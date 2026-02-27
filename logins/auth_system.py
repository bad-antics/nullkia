#!/usr/bin/env python3
"""
NullKia Authentication System
Custom login with session management
@author bad-antics
@discord x.com/AnonAntics
"""

import hashlib
import secrets
import json
import os
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Any
import base64
import hmac

VERSION = "2.0.0"
AUTHOR = "bad-antics"
DISCORD = "x.com/AnonAntics"

BANNER = """
╭──────────────────────────────────────────╮
│        📱 NULLKIA AUTHENTICATION         │
│       ════════════════════════════       │
│                                          │
│   🔐 Secure Session Management           │
│   🔑 License Key Validation              │
│   👤 User Profile System                 │
│                                          │
│            bad-antics | NullSec         │
╰──────────────────────────────────────────╯
"""

# Configuration
CONFIG_DIR = Path.home() / ".nullkia"
AUTH_DIR = CONFIG_DIR / "auth"
USERS_FILE = AUTH_DIR / "users.json"
SESSIONS_FILE = AUTH_DIR / "sessions.json"
LICENSES_FILE = AUTH_DIR / "licenses.json"

# Ensure directories exist
AUTH_DIR.mkdir(parents=True, exist_ok=True)


class Colors:
    """Terminal colors"""
    RESET = "\x1b[0m"
    RED = "\x1b[31m"
    GREEN = "\x1b[32m"
    YELLOW = "\x1b[33m"
    BLUE = "\x1b[34m"
    CYAN = "\x1b[36m"
    BOLD = "\x1b[1m"
    
    @classmethod
    def success(cls, msg: str):
        print(f"{cls.GREEN}✅ {msg}{cls.RESET}")
    
    @classmethod
    def error(cls, msg: str):
        print(f"{cls.RED}❌ {msg}{cls.RESET}")
    
    @classmethod
    def warning(cls, msg: str):
        print(f"{cls.YELLOW}⚠️  {msg}{cls.RESET}")
    
    @classmethod
    def info(cls, msg: str):
        print(f"{cls.BLUE}ℹ️  {msg}{cls.RESET}")


class LicenseTier:
    FREE = "free"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"


class PasswordHasher:
    """Secure password hashing with salt"""
    
    @staticmethod
    def hash_password(password: str, salt: Optional[bytes] = None) -> tuple[str, str]:
        """Hash password with salt"""
        if salt is None:
            salt = secrets.token_bytes(32)
        
        # Use PBKDF2 with SHA256
        key = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt,
            iterations=100000
        )
        
        return base64.b64encode(key).decode(), base64.b64encode(salt).decode()
    
    @staticmethod
    def verify_password(password: str, stored_hash: str, salt: str) -> bool:
        """Verify password against stored hash"""
        salt_bytes = base64.b64decode(salt)
        computed_hash, _ = PasswordHasher.hash_password(password, salt_bytes)
        return hmac.compare_digest(computed_hash, stored_hash)


class LicenseManager:
    """License validation and management"""
    
    def __init__(self):
        self.licenses = self._load_licenses()
    
    def _load_licenses(self) -> Dict[str, Any]:
        """Load licenses from file"""
        if LICENSES_FILE.exists():
            try:
                return json.loads(LICENSES_FILE.read_text())
            except:
                pass
        return {}
    
    def _save_licenses(self):
        """Save licenses to file"""
        LICENSES_FILE.write_text(json.dumps(self.licenses, indent=2))
    
    def validate_license(self, key: str) -> tuple[bool, str]:
        """Validate license key format and return tier"""
        # Format: NKIA-XXXX-XXXX-XXXX-XXXX
        if len(key) != 24 or not key.startswith("NKIA-"):
            return False, LicenseTier.FREE
        
        parts = key.split("-")
        if len(parts) != 5:
            return False, LicenseTier.FREE
        
        # Check tier code
        tier_code = parts[1][:2]
        if tier_code == "PR":
            return True, LicenseTier.PREMIUM
        elif tier_code == "EN":
            return True, LicenseTier.ENTERPRISE
        
        return True, LicenseTier.FREE
    
    def register_license(self, username: str, key: str) -> bool:
        """Register license key for user"""
        valid, tier = self.validate_license(key)
        if not valid:
            return False
        
        self.licenses[username] = {
            "key": key,
            "tier": tier,
            "registered_at": datetime.now().isoformat(),
            "valid": True
        }
        self._save_licenses()
        return True
    
    def get_user_tier(self, username: str) -> str:
        """Get user's license tier"""
        if username in self.licenses:
            return self.licenses[username].get("tier", LicenseTier.FREE)
        return LicenseTier.FREE
    
    def is_premium(self, username: str) -> bool:
        """Check if user has premium access"""
        tier = self.get_user_tier(username)
        return tier in [LicenseTier.PREMIUM, LicenseTier.ENTERPRISE]


class SessionManager:
    """Session management for authenticated users"""
    
    TOKEN_LENGTH = 64
    SESSION_DURATION = timedelta(hours=24)
    
    def __init__(self):
        self.sessions = self._load_sessions()
    
    def _load_sessions(self) -> Dict[str, Any]:
        """Load sessions from file"""
        if SESSIONS_FILE.exists():
            try:
                sessions = json.loads(SESSIONS_FILE.read_text())
                # Clean expired sessions
                now = datetime.now().isoformat()
                return {
                    k: v for k, v in sessions.items()
                    if v.get("expires_at", "") > now
                }
            except:
                pass
        return {}
    
    def _save_sessions(self):
        """Save sessions to file"""
        SESSIONS_FILE.write_text(json.dumps(self.sessions, indent=2))
    
    def create_session(self, username: str) -> str:
        """Create new session for user"""
        token = secrets.token_hex(self.TOKEN_LENGTH)
        expires_at = datetime.now() + self.SESSION_DURATION
        
        self.sessions[token] = {
            "username": username,
            "created_at": datetime.now().isoformat(),
            "expires_at": expires_at.isoformat(),
            "last_active": datetime.now().isoformat()
        }
        self._save_sessions()
        return token
    
    def validate_session(self, token: str) -> Optional[str]:
        """Validate session token and return username"""
        if token not in self.sessions:
            return None
        
        session = self.sessions[token]
        if datetime.fromisoformat(session["expires_at"]) < datetime.now():
            del self.sessions[token]
            self._save_sessions()
            return None
        
        # Update last active
        session["last_active"] = datetime.now().isoformat()
        self._save_sessions()
        
        return session["username"]
    
    def destroy_session(self, token: str):
        """Destroy session"""
        if token in self.sessions:
            del self.sessions[token]
            self._save_sessions()
    
    def get_user_sessions(self, username: str) -> list:
        """Get all sessions for user"""
        return [
            {"token": k[:16] + "...", **v}
            for k, v in self.sessions.items()
            if v["username"] == username
        ]


class UserManager:
    """User account management"""
    
    def __init__(self):
        self.users = self._load_users()
        self.license_manager = LicenseManager()
        self.session_manager = SessionManager()
    
    def _load_users(self) -> Dict[str, Any]:
        """Load users from file"""
        if USERS_FILE.exists():
            try:
                return json.loads(USERS_FILE.read_text())
            except:
                pass
        return {}
    
    def _save_users(self):
        """Save users to file"""
        USERS_FILE.write_text(json.dumps(self.users, indent=2))
    
    def register(self, username: str, password: str, email: str = "") -> tuple[bool, str]:
        """Register new user"""
        if len(username) < 3:
            return False, "Username must be at least 3 characters"
        
        if len(password) < 6:
            return False, "Password must be at least 6 characters"
        
        if username in self.users:
            return False, "Username already exists"
        
        # Hash password
        password_hash, salt = PasswordHasher.hash_password(password)
        
        self.users[username] = {
            "password_hash": password_hash,
            "salt": salt,
            "email": email,
            "created_at": datetime.now().isoformat(),
            "last_login": None,
            "profile": {
                "display_name": username,
                "avatar": "default",
                "discord": "",
                "github": ""
            }
        }
        self._save_users()
        
        return True, "Registration successful"
    
    def login(self, username: str, password: str) -> tuple[bool, str]:
        """Login user and return session token"""
        if username not in self.users:
            return False, "Invalid username or password"
        
        user = self.users[username]
        
        if not PasswordHasher.verify_password(
            password,
            user["password_hash"],
            user["salt"]
        ):
            return False, "Invalid username or password"
        
        # Update last login
        user["last_login"] = datetime.now().isoformat()
        self._save_users()
        
        # Create session
        token = self.session_manager.create_session(username)
        
        return True, token
    
    def logout(self, token: str) -> bool:
        """Logout user"""
        self.session_manager.destroy_session(token)
        return True
    
    def change_password(self, username: str, old_password: str, new_password: str) -> tuple[bool, str]:
        """Change user password"""
        if username not in self.users:
            return False, "User not found"
        
        user = self.users[username]
        
        if not PasswordHasher.verify_password(old_password, user["password_hash"], user["salt"]):
            return False, "Current password is incorrect"
        
        if len(new_password) < 6:
            return False, "New password must be at least 6 characters"
        
        password_hash, salt = PasswordHasher.hash_password(new_password)
        user["password_hash"] = password_hash
        user["salt"] = salt
        self._save_users()
        
        return True, "Password changed successfully"
    
    def update_profile(self, username: str, profile_data: dict) -> bool:
        """Update user profile"""
        if username not in self.users:
            return False
        
        user = self.users[username]
        for key in ["display_name", "avatar", "discord", "github"]:
            if key in profile_data:
                user["profile"][key] = profile_data[key]
        
        self._save_users()
        return True
    
    def get_user_info(self, username: str) -> Optional[dict]:
        """Get user info (excluding password)"""
        if username not in self.users:
            return None
        
        user = self.users[username].copy()
        del user["password_hash"]
        del user["salt"]
        
        user["license_tier"] = self.license_manager.get_user_tier(username)
        user["is_premium"] = self.license_manager.is_premium(username)
        
        return user


class AuthCLI:
    """Command-line interface for authentication"""
    
    def __init__(self):
        self.user_manager = UserManager()
        self.current_token = None
        self.current_user = None
    
    def show_banner(self):
        """Display banner"""
        print(f"{Colors.CYAN}{BANNER}{Colors.RESET}")
    
    def show_menu_logged_out(self):
        """Show menu for logged out users"""
        print("\n📋 Menu:\n")
        print("  [1] Login")
        print("  [2] Register")
        print("  [3] About")
        print("  [0] Exit")
        print()
    
    def show_menu_logged_in(self):
        """Show menu for logged in users"""
        tier = self.user_manager.license_manager.get_user_tier(self.current_user)
        tier_badge = "🆓" if tier == LicenseTier.FREE else "⭐" if tier == LicenseTier.PREMIUM else "💎"
        
        print(f"\n👤 Logged in as: {Colors.BOLD}{self.current_user}{Colors.RESET} {tier_badge}")
        print("\n📋 Menu:\n")
        print("  [1] Profile")
        print("  [2] Change Password")
        print("  [3] License Management")
        print("  [4] Active Sessions")
        print("  [5] Update Profile")
        print("  [6] Logout")
        print("  [0] Exit")
        print()
    
    def handle_register(self):
        """Handle user registration"""
        print("\n📝 Registration\n")
        
        username = input("Username: ").strip()
        email = input("Email (optional): ").strip()
        password = input("Password: ").strip()
        confirm = input("Confirm password: ").strip()
        
        if password != confirm:
            Colors.error("Passwords do not match")
            return
        
        success, message = self.user_manager.register(username, password, email)
        if success:
            Colors.success(message)
        else:
            Colors.error(message)
    
    def handle_login(self):
        """Handle user login"""
        print("\n🔐 Login\n")
        
        username = input("Username: ").strip()
        password = input("Password: ").strip()
        
        success, result = self.user_manager.login(username, password)
        if success:
            self.current_token = result
            self.current_user = username
            Colors.success(f"Welcome back, {username}!")
        else:
            Colors.error(result)
    
    def handle_logout(self):
        """Handle user logout"""
        if self.current_token:
            self.user_manager.logout(self.current_token)
        self.current_token = None
        self.current_user = None
        Colors.success("Logged out successfully")
    
    def handle_profile(self):
        """Display user profile"""
        info = self.user_manager.get_user_info(self.current_user)
        if not info:
            return
        
        print("\n👤 Profile\n")
        print(f"  Username: {self.current_user}")
        print(f"  Display Name: {info['profile']['display_name']}")
        print(f"  Email: {info.get('email', 'Not set')}")
        print(f"  Created: {info['created_at']}")
        print(f"  Last Login: {info.get('last_login', 'Never')}")
        print(f"  License Tier: {info['license_tier'].upper()}")
        print(f"  Premium: {'Yes' if info['is_premium'] else 'No'}")
        
        if info['profile'].get('discord'):
            print(f"  Discord: {info['profile']['discord']}")
        if info['profile'].get('github'):
            print(f"  GitHub: {info['profile']['github']}")
    
    def handle_change_password(self):
        """Handle password change"""
        print("\n🔑 Change Password\n")
        
        old_password = input("Current password: ").strip()
        new_password = input("New password: ").strip()
        confirm = input("Confirm new password: ").strip()
        
        if new_password != confirm:
            Colors.error("Passwords do not match")
            return
        
        success, message = self.user_manager.change_password(
            self.current_user, old_password, new_password
        )
        
        if success:
            Colors.success(message)
        else:
            Colors.error(message)
    
    def handle_license(self):
        """Handle license management"""
        print("\n🔑 License Management\n")
        
        tier = self.user_manager.license_manager.get_user_tier(self.current_user)
        print(f"  Current Tier: {tier.upper()}")
        
        if tier == LicenseTier.FREE:
            print("\n  Get premium at x.com/AnonAntics")
        
        print("\n  [1] Enter License Key")
        print("  [0] Back")
        
        choice = input("\nSelect: ").strip()
        
        if choice == "1":
            key = input("Enter license key: ").strip()
            if self.user_manager.license_manager.register_license(self.current_user, key):
                new_tier = self.user_manager.license_manager.get_user_tier(self.current_user)
                Colors.success(f"License activated! Tier: {new_tier.upper()}")
            else:
                Colors.error("Invalid license key")
    
    def handle_sessions(self):
        """Handle active sessions"""
        sessions = self.user_manager.session_manager.get_user_sessions(self.current_user)
        
        print("\n🔐 Active Sessions\n")
        for session in sessions:
            print(f"  Token: {session['token']}")
            print(f"  Created: {session['created_at']}")
            print(f"  Expires: {session['expires_at']}")
            print(f"  Last Active: {session['last_active']}")
            print()
    
    def handle_update_profile(self):
        """Handle profile update"""
        print("\n📝 Update Profile\n")
        print("  (Press Enter to skip)\n")
        
        display_name = input("Display Name: ").strip()
        discord = input("Discord Username: ").strip()
        github = input("GitHub Handle: ").strip()
        
        profile_data = {}
        if display_name:
            profile_data["display_name"] = display_name
        if discord:
            profile_data["discord"] = discord
        if github:
            profile_data["github"] = github
        
        if profile_data:
            self.user_manager.update_profile(self.current_user, profile_data)
            Colors.success("Profile updated")
        else:
            Colors.info("No changes made")
    
    def show_about(self):
        """Show about information"""
        print(f"\n📱 NullKia Authentication System v{VERSION}")
        print(f"   Author: {AUTHOR}")
        print(f"   Discord: {DISCORD}")
        print(f"   GitHub: bad-antics")
        print()
        print("   Premium features available at x.com/AnonAntics")
    
    def run(self):
        """Run the CLI"""
        self.show_banner()
        
        running = True
        while running:
            if self.current_user:
                self.show_menu_logged_in()
                choice = input("Select: ").strip()
                
                if choice == "1":
                    self.handle_profile()
                elif choice == "2":
                    self.handle_change_password()
                elif choice == "3":
                    self.handle_license()
                elif choice == "4":
                    self.handle_sessions()
                elif choice == "5":
                    self.handle_update_profile()
                elif choice == "6":
                    self.handle_logout()
                elif choice == "0":
                    running = False
            else:
                self.show_menu_logged_out()
                choice = input("Select: ").strip()
                
                if choice == "1":
                    self.handle_login()
                elif choice == "2":
                    self.handle_register()
                elif choice == "3":
                    self.show_about()
                elif choice == "0":
                    running = False
        
        print("\n─────────────────────────────────────────")
        print("📱 NullKia Authentication")
        print("🔑 Premium: x.com/AnonAntics")
        print("🐦 GitHub: bad-antics")
        print("─────────────────────────────────────────\n")


if __name__ == "__main__":
    cli = AuthCLI()
    cli.run()
