from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup

app = Flask(__name__)
CORS(app)

# Fetch search results
def fetch_top_search_results(api_key, search_engine_id, query):
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        'key': api_key,
        'cx': search_engine_id,
        'q': query,
        'num': 2
    }
    response = requests.get(url, params=params)
    print(f"Google Search Response: {response.status_code}, {response.text}")  # Debugging
    if response.status_code == 200:
        return [item['link'] for item in response.json().get('items', [])]
    return []

# Scrape content
def scrape_content(url):
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            paragraphs = [p.text.strip() for p in soup.find_all('p') if p.text.strip()]
            return {'url': url, 'content': paragraphs}
    except Exception as e:
        print(f"Scraping error for {url}: {e}")
    return {'url': url, 'error': 'Failed to fetch content'}

# Summarize content
def summarize_using_groq(api_key, text, city):
    url = 'https://api.groq.com/openai/v1/chat/completions'
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    request_body = {
        "messages": [{"role": "user", "content": f"Generate a concise and informative travel alert for {city} based on the following content:-{text}. The response should be clear, accurate, and free of uncertain statements. If the scraped content is insufficient or unreliable, simply state that it is safe to travel, without any extraneous commentary or disclaimers.remember tihis response is directly displaye to app. do not address in first person. max 150 words no markdown in response first line states things like hurricane  alert/heat wave alert/good time to travel/etc..from site insignts else safe"}],
        "model": "llama-3.1-8b-instant",
        "temperature": 1.0,
        "max_tokens": 1000,
        "top_p": 1.0,
    }
    response = requests.post(url, headers=headers, json=request_body)
    print(f"GROQ Response: {response.status_code}, {response.text}")
    if response.status_code == 200:
        return response.json()['choices'][0]['message']['content']
    return "Safe to travel."

@app.route('/scrape', methods=['POST'])
def scrape_and_summarize():
    data = request.json
    city = data.get("city", "")
    if not city:
        return jsonify({"error": "City is required"}), 400

    api_key = "AIzaSyDV1E4fRcVZA8mendvCg01HsaWircJA6gE"
    search_engine_id = "67e57388be1eb412c"
    query = f"{city} travel alerts news:.com"

    try:
        urls = fetch_top_search_results(api_key, search_engine_id, query)
        scraped_data = [scrape_content(url) for url in urls]
        aggregated_content = "\n\n".join(
            ["\n".join(item.get('content', [])) for item in scraped_data]
        )

        groq_api_key = "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"
        summary = summarize_using_groq(groq_api_key, aggregated_content, city)

        return jsonify({
            "city": city,
            "content": summary,
            "sources": urls
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)