"""
Database setup and helper functions using TinyDB.
"""
import os
from tinydb import TinyDB, Query
from typing import Dict, Any, Optional

# Ensure data directory exists
os.makedirs('data', exist_ok=True)

# Initialize TinyDB - JSON file-based database
db = TinyDB('data/database.json', indent=2)
users_table = db.table('users')
tasks_table = db.table('tasks')
history_table = db.table('history')
documents_table = db.table('documents')

# Query helper
User = Query()


def get_user(user_id: str) -> Optional[Dict[str, Any]]:
    """Get user by ID"""
    return users_table.get(User.user_id == user_id)


def update_user(user_id: str, data: Dict[str, Any]) -> bool:
    """Update user data"""
    existing = users_table.get(User.user_id == user_id)
    if existing:
        merged = {**existing, **data}
        users_table.update(merged, User.user_id == user_id)
        return True
    else:
        data["user_id"] = user_id
        users_table.insert(data)
        return True


def create_user(user_id: str, data: Dict[str, Any]) -> bool:
    """Create a new user"""
    data["user_id"] = user_id
    users_table.insert(data)
    return True
