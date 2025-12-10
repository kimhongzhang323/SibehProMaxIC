"""
Chat-related API endpoints.
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
import httpx
import json
import re

from config import GEMINI_API_KEY, ELEVENLABS_API_KEY, GOOGLE_MAPS_API_KEY, VOICE_IDS
from models import ChatRequest
from knowledge_base import GOVERNMENT_SERVICES
from prompts import SYSTEM_PROMPTS

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("")
async def chat(request: ChatRequest):
    """Main chat endpoint with Gemini AI"""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")
    
    language = request.language.lower()
    if language not in SYSTEM_PROMPTS:
        language = "english"
    
    system_prompt = SYSTEM_PROMPTS[language]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}",
            json={
                "contents": [
                    {"role": "user", "parts": [{"text": f"{system_prompt}\n\nUser message: {request.message}"}]}
                ],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 1024,
                }
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Gemini API error")
        
        data = response.json()
        text = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        
        # Try to parse as JSON
        try:
            json_match = re.search(r'\{[\s\S]*\}', text)
            if json_match:
                return json.loads(json_match.group())
        except json.JSONDecodeError:
            pass
        
        return {"response": text, "type": "text"}


@router.post("/simple")
async def simple_chat(request: ChatRequest):
    """Simple chat endpoint returning text only"""
    result = await chat(request)
    if isinstance(result, dict) and "response" in result:
        return {"response": result["response"]}
    return {"response": str(result)}


@router.post("/tts")
async def text_to_speech(text: str, language: str = "english"):
    """Convert text to speech using ElevenLabs"""
    if not ELEVENLABS_API_KEY:
        raise HTTPException(status_code=500, detail="ElevenLabs API key not configured")
    
    voice_id = VOICE_IDS.get(language.lower(), VOICE_IDS["english"])
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
            headers={
                "xi-api-key": ELEVENLABS_API_KEY,
                "Content-Type": "application/json"
            },
            json={
                "text": text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.75
                }
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="TTS API error")
        
        return Response(content=response.content, media_type="audio/mpeg")


@router.get("/locations/{service}")
async def get_service_locations(service: str, lat: float = 3.139, lng: float = 101.6869):
    """Get nearby government office locations"""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(status_code=500, detail="Google Maps API key not configured")
    
    service_info = GOVERNMENT_SERVICES.get(service.lower())
    if not service_info:
        raise HTTPException(status_code=404, detail=f"Unknown service: {service}")
    
    search_query = service_info["search_term"]
    
    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            params={
                "location": f"{lat},{lng}",
                "radius": 10000,
                "keyword": search_query,
                "key": GOOGLE_MAPS_API_KEY
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Maps API error")
        
        data = response.json()
        results = data.get("results", [])[:5]
        
        locations = []
        for place in results:
            locations.append({
                "name": place.get("name"),
                "address": place.get("vicinity"),
                "lat": place.get("geometry", {}).get("location", {}).get("lat"),
                "lng": place.get("geometry", {}).get("location", {}).get("lng"),
                "rating": place.get("rating"),
                "open_now": place.get("opening_hours", {}).get("open_now")
            })
        
        return {
            "service": service_info["name"],
            "locations": locations,
            "website": service_info["website"],
            "hotline": service_info["hotline"]
        }
