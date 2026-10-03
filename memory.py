import sqlite3
from datetime import datetime


DATABASE_PATH = "jarvis_memory.db"


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():
    return sqlite3.connect(DATABASE_PATH)


# ============================================================
# INITIALIZE DATABASE
# ============================================================

def initialize_memory():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            category TEXT DEFAULT 'general',
            created_at TEXT NOT NULL
        )
    """)

    conn.commit()
    conn.close()


# ============================================================
# REMEMBER
# ============================================================

def remember(content, category="general"):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO memories (content, category, created_at)
        VALUES (?, ?, ?)
        """,
        (
            content,
            category,
            datetime.now().isoformat(),
        ),
    )

    conn.commit()
    conn.close()

    print(f"[MEMORY] Remembered: {content}")


# ============================================================
# GET ALL MEMORIES
# ============================================================

def get_all_memories():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, content, category, created_at
        FROM memories
        ORDER BY id DESC
    """)

    memories = cursor.fetchall()

    conn.close()

    return memories


# ============================================================
# SEARCH MEMORIES
# ============================================================

def search_memories(query):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT id, content, category, created_at
        FROM memories
        WHERE content LIKE ?
        ORDER BY id DESC
        """,
        (f"%{query}%",),
    )

    memories = cursor.fetchall()

    conn.close()

    return memories


# ============================================================
# FORGET MEMORY
# ============================================================

def forget_memory(memory_id):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        DELETE FROM memories
        WHERE id = ?
        """,
        (memory_id,),
    )

    deleted = cursor.rowcount > 0

    conn.commit()
    conn.close()

    return deleted