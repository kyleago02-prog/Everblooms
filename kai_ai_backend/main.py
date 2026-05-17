import os
import logging
from typing import List, Dict, Optional
# pyrefly: ignore [missing-import]
from fastapi import FastAPI, HTTPException, Body
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests
from dotenv import load_dotenv

# Set up logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("kai-ai-backend")

# Load environment variables
load_dotenv()

# OpenRouter Configuration
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
if not OPENROUTER_API_KEY:
    logger.warning("OPENROUTER_API_KEY is not set in environment or .env file. The chatbot will not function properly.")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
# We can use a fast, cost-effective model on OpenRouter like google/gemini-2.5-flash or mistralai/mistral-7b-instruct
MODEL_NAME = os.getenv("MODEL_NAME", "google/gemini-2.5-flash")

app = FastAPI(title="Kai AI - EverBloom Chatbot")

# Add CORS Middleware to allow requests from any host (e.g. Flutter Web or mobile tests)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory session store: maps session_id to list of chat message dicts
sessions_db: Dict[str, List[Dict[str, str]]] = {}

# System prompt for Kai AI
SYSTEM_PROMPT = """You are Kai AI, a friendly, cute, and calming chatbot assistant inside the EverBloom app.

EverBloom is a flower-inspired experience, so your personality must feel:
- soft
- warm
- gentle
- aesthetic
- nature-themed (flowers, gardens, sunlight, breeze)

Your role:
You help users with app guidance, simple questions, casual conversation, and supportive assistance.

Behavior rules:
- Always respond in a calm, friendly tone.
- Give precise, clear, and easily understandable answers.
- Keep responses short, clear, and direct. Avoid long, overwhelming paragraphs.
- Do NOT use asterisk symbols (*) anywhere in your output (e.g., do NOT write *smiles*, *soft breeze*, or use * for bold/italic). Rely on natural text and standard emojis instead.
- Support multilingual conversations naturally: If the user speaks or asks in Tagalog or Bisaya, you MUST respond warmly and precisely in Tagalog or Bisaya (e.g., Tagalog: "Kumusta, magandang bulaklak! May maitutulong ba ako sa 'yo ngayon?", Bisaya: "Musta, maayong adlaw! Unsa may akong matabang nimo karon?"). Keep the floral/nature theme alive in all languages!
- Do NOT be robotic or overly formal.
- Be emotionally supportive but not dramatic or exaggerated.
- Focus on helping inside the EverBloom app experience.

EverBloom Features (use this to help users if they ask):
- EverBloom is a flower marketplace connecting customers with local florists.
- Customers can search for flowers and florists, check detailed florist store pages and ratings, see florist locations on an interactive Map, place orders, and track orders from the Orders page.
- There are gorgeous flower cards and top-rated florists on the Home Screen.
- There's an easy Navigation Bar to move between Home, Search, Orders, and Profile.

If user asks about EverBloom features:
- Explain simply and clearly, and guide them step-by-step.

If user is casual:
- Match their tone and keep it light, playful, and friendly.

Always stay as Kai AI inside EverBloom. Never break character."""

class ChatRequest(BaseModel):
    message: str
    session_id: str = "default_session"

class ChatResponse(BaseModel):
    reply: str
    session_id: str

@app.get("/")
def read_root():
    return {
        "status": "online",
        "app": "EverBloom Kai AI Assistant Backend",
        "model": MODEL_NAME
    }

@app.post("/api/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    session_id = request.session_id
    user_message = request.message.strip()

    if not user_message:
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    # Retrieve or initialize session history
    if session_id not in sessions_db:
        sessions_db[session_id] = [{"role": "system", "content": SYSTEM_PROMPT}]
    
    # Check if system prompt is present, if not add it (e.g., if history was wiped but not system)
    history = sessions_db[session_id]
    if not history or history[0]["role"] != "system":
        history.insert(0, {"role": "system", "content": SYSTEM_PROMPT})

    # Append user message
    history.append({"role": "user", "content": user_message})

    # Limit history to prevent token bloat (keep system prompt + last 20 messages)
    if len(history) > 21:
        # Keep system prompt at index 0, and slice last 20 items
        sessions_db[session_id] = [history[0]] + history[-20:]
        history = sessions_db[session_id]

    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:8000",
        "X-Title": "EverBloom Kai AI Assistant"
    }

    payload = {
        "model": MODEL_NAME,
        "messages": history,
        "temperature": 0.7,
        "max_tokens": 500
    }

    try:
        logger.info(f"Sending request to OpenRouter for session {session_id} using model {MODEL_NAME}")
        response = requests.post(OPENROUTER_URL, json=payload, headers=headers, timeout=15)
        
        if response.status_code != 200:
            logger.error(f"OpenRouter API returned error status {response.status_code}: {response.text}")
            # Try a fallback model if the specified model fails
            if MODEL_NAME != "meta-llama/llama-3-8b-instruct:free":
                logger.info("Retrying with fallback free model...")
                payload["model"] = "meta-llama/llama-3-8b-instruct:free"
                response = requests.post(OPENROUTER_URL, json=payload, headers=headers, timeout=15)

        if response.status_code == 200:
            res_data = response.json()
            reply = res_data["choices"][0]["message"]["content"]
            
            # Save assistant reply to history
            history.append({"role": "assistant", "content": reply})
            
            return ChatResponse(reply=reply, session_id=session_id)
        else:
            raise HTTPException(
                status_code=502, 
                detail=f"OpenRouter API returned error: {response.text}"
            )

    except requests.exceptions.Timeout:
        logger.error("Timeout connecting to OpenRouter API")
        raise HTTPException(status_code=504, detail="Request to AI service timed out. Please try again.")
    except Exception as e:
        logger.exception("Error in chat endpoint")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@app.post("/api/chat/clear")
def clear_chat(session_id: str = Body(..., embed=True)):
    """Clears history for a session but keeps system prompt."""
    if session_id in sessions_db:
        sessions_db[session_id] = [{"role": "system", "content": SYSTEM_PROMPT}]
    return {"status": "success", "message": f"Chat history for session '{session_id}' cleared."}

if __name__ == "__main__":
    import uvicorn
    # Default to 0.0.0.0 so we can access it from local emulator or local network
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
