import Console.config as config
from googleapiclient.discovery import build
import re

def extract_video_id(url):
    pattern = r'(?:v=|\/)([0-9A-Za-z_-]{11}).*'
    match = re.search(pattern, url)
    return match.group(1) if match else url

def get_video_owner_id(youtube, video_id):
    request = youtube.videos().list(part="snippet", id=video_id)
    response = request.execute()
    return response["items"][0]["snippet"]["channelId"] if response.get("items") else None

def get_representative_comments(video_id, count=10):
    youtube = build("youtube", "v3", developerKey=config.YOUTUBE_API_KEY)
    owner_id = get_video_owner_id(youtube, video_id)

    request = youtube.commentThreads().list(
        part="snippet",
        videoId=video_id,
        maxResults=count + 5, 
        order="relevance",
        textFormat="plainText"
    )
    response = request.execute()
    
    comments_data = []
    for item in response.get("items", []):
        snippet = item['snippet']['topLevelComment']['snippet']
        
        # 1. Grab Author ID internally for the filter check
        author_id = snippet.get('authorChannelId', {}).get('value')

        # 2. Filter: Skip if it's the video creator
        if author_id == owner_id:
            continue
            
        text = snippet['textDisplay']
        safe_text = (text[:497] + '...') if len(text) > 500 else text

        # 3. Clean Data: We store ONLY what AWS needs
        comments_data.append({
            "text": safe_text, 
            "likes": snippet['likeCount']
        })
        
        if len(comments_data) >= count:
            break
        
    return comments_data

if __name__ == "__main__":
    raw_input = input("Enter YouTube URL or Video ID: ").strip()
    v_id = extract_video_id(raw_input)
    
    try:
        results = get_representative_comments(v_id)
        
        print(f"\n--- Top {len(results)} Community Comments (Anonymized for AWS) ---\n")
        
        for i, c in enumerate(results, 1):
            # We only print the text and likes now - no 'author' field used
            print(f"Comment #{i} ({c['likes']} Likes):")
            print(f"   {c['text']}") 
            print("-" * 30) 
            
    except Exception as e:
        print(f"Error: {e}")