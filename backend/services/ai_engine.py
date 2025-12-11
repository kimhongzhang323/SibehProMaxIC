
from datetime import datetime, timedelta

class AnomalyDetector:
    def __init__(self):
        self.access_logs = {} # {user_id: [timestamp]}
        
    def check_behavior(self, user_id, event_type, metadata=None):
        """
        Analyze user behavior for anomalies.
        Returns: (is_anomaly: bool, risk_score: float, reason: str)
        """
        now = datetime.now()
        
        # 1. Frequency Analysis (Rate Limiting)
        if user_id not in self.access_logs:
            self.access_logs[user_id] = []
            
        timestamps = self.access_logs[user_id]
        # Clean old logs (> 1 hour)
        timestamps = [t for t in timestamps if t > now - timedelta(hours=1)]
        timestamps.append(now)
        self.access_logs[user_id] = timestamps
        
        # If > 10 requests in 1 minute -> Anomaly (Bot attack)
        recent_requests = [t for t in timestamps if t > now - timedelta(minutes=1)]
        if len(recent_requests) > 10:
            return True, 0.9, "High frequency access detected (Potential Bot)"
            
        # 2. Time-based Anomaly (Impossible Travel - Mocked)
        # If accessing from "London" 1 min after "KL" -> Anomaly
        # Since we don't have location in all requests, we skip this for now.
        
        # 3. Sensitive Action check
        if event_type == "revoke":
            return False, 0.1, "User initiated revocation" # Not anomaly, but high importance
            
        return False, 0.0, "Normal behavior"

ai_engine = AnomalyDetector()
