import os
import re
import json
import boto3
from botocore.exceptions import ClientError
from googleapiclient.discovery import build

def extract_video_id(url):
    pattern = r'(?:v=|\/)([0-9A-Za-z_-]{11})'
    match = re.search(pattern, url)
    if match: return match.group(1)
    if re.match(r'^[0-9A-Za-z_-]{11}$', url): return url
    return None

def get_video_metadata(youtube, video_id):
    request = youtube.videos().list(part="snippet", id=video_id)
    response = request.execute()
    if not response.get("items"): return None
    snippet = response["items"][0]["snippet"]
    return {
        "owner_id": snippet["channelId"],
        "video_title": snippet["title"],
        "creator_name": snippet["channelTitle"]
    }

def lambda_handler(event, context):
    if "body" in event:
        try:
            body_data = json.loads(event["body"])
            raw_input = body_data.get("video_input", "").strip()
        except Exception:
            raw_input = ""
    else:
        # Fallback for your manual AWS Console 'Test' events
        raw_input = event.get("video_input", "").strip()
        
    video_id = extract_video_id(raw_input)
    if not video_id:
        return {"statusCode": 400, "error": "Invalid Input", "message": "Please enter a valid YouTube URL."}
    
    api_key = os.environ.get('YOUTUBE_API_KEY')
    youtube = build("youtube", "v3", developerKey=api_key)
    
    # Singapore endpoints
    translate_client = boto3.client('translate', region_name='ap-southeast-1')
    comprehend_client = boto3.client('comprehend', region_name='ap-southeast-1')
    bedrock_runtime = boto3.client('bedrock-runtime', region_name='ap-southeast-1')
    
    try:
        meta = get_video_metadata(youtube, video_id)
        if not meta: return {"statusCode": 404, "error": "Not Found", "message": "YouTube video not found."}
        
        owner_id = meta["owner_id"]
        request = youtube.commentThreads().list(
            part="snippet", videoId=video_id, maxResults=15, order="relevance", textFormat="plainText"
        )
        response = request.execute()
        
        comments_list = []
        raw_text_batch = []
        
        # 1. Scraping and Translation Loop
        for item in response.get("items", []):
            snippet = item['snippet']['topLevelComment']['snippet']
            if snippet.get('authorChannelId', {}).get('value') == owner_id: continue
                
            text = snippet['textDisplay']
            safe_text = (text[:497] + '...') if len(text) > 500 else text
            
            final_text = safe_text
            detected_lang = "en"
            try:
                translate_response = translate_client.translate_text(Text=safe_text, SourceLanguageCode='auto', TargetLanguageCode='en')
                detected_lang = translate_response.get('SourceLanguageCode')
                if detected_lang != 'en': final_text = translate_response.get('TranslatedText')
            except ClientError as e:
                if e.response['Error']['Code'] in ['UnsupportedLanguagePairException', 'DetectedLanguageLowConfidenceException']:
                    return {"statusCode": 422, "error": "Unsupported Language", "message": "Unsupported language."}
                raise e

            comments_list.append({"text": final_text, "likes": snippet['likeCount'], "original_language": detected_lang})
            raw_text_batch.append(final_text)
            if len(comments_list) >= 10: break
                
        # 2. Batch Sentiment Integration
        sentiment_distribution = {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0, "MIXED": 0}
        
        if raw_text_batch:
            comprehend_response = comprehend_client.batch_detect_sentiment(TextList=raw_text_batch, LanguageCode='en')
            for result in comprehend_response.get('ResultList', []):
                idx = result['Index']
                verdict = result['Sentiment']
                comments_list[idx]['sentiment'] = verdict
                
                if verdict in sentiment_distribution:
                    sentiment_distribution[verdict] += 1

        total_analyzed = len(comments_list) if comments_list else 1
        ratios = {k: round((v / total_analyzed) * 100, 1) for k, v in sentiment_distribution.items()}

        # 3. Amazon Bedrock AI Summary Generation (using Nova Micro)
        ai_summary = "No summary available."
        if comments_list:
            formatted_comments_for_ai = "\n".join([f"- [{c.get('sentiment')}]: {c['text']}" for c in comments_list])
            
            prompt = f"""You are an expert audience analyst. Analyze the following 10 comments for the YouTube video titled "{meta['video_title']}" by creator "{meta['creator_name']}". 
            Provide a precise, 2-sentence summary explaining the audience's primary reactions and what they think about the content. Do not mention individual usernames. Keep it objective.
            
            Comments:
            {formatted_comments_for_ai}
            """
            
            try:
                bedrock_response = bedrock_runtime.converse(
                    modelId="apac.amazon.nova-micro-v1:0", # Updated to Nova Micro ID
                    messages=[{"role": "user", "content": [{"text": prompt}]}],
                    inferenceConfig={"maxTokens": 150, "temperature": 0.3}
                )
                ai_summary = bedrock_response['output']['message']['content'][0]['text'].strip()
            except Exception as b_err:
                print(f"Bedrock Error: {str(b_err)}")
                ai_summary = "Could not generate AI summary due to model restrictions or configuration."

        response_payload = {
            "video_id": video_id,
            "video_title": meta["video_title"],
            "creator_name": meta["creator_name"],
            "sentiment_ratios": ratios,
            "ai_summary": ai_summary,
            "comments": comments_list
        }

        # Pack it inside the mandatory API Gateway container format
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" # Double-down on CORS safety
            },
            "body": json.dumps(response_payload) # Must be stringified!
        }
        
    except Exception as e:
        # We extract the string version of the actual error 'str(e)' 
        # and safely pass it forward inside our JSON response body
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "error": "Internal Server Error", 
                "message": str(e)  # <-- This passes the real culprit to your website!
            })
        }