// ═══════════════════════════════════════════════════════════════════
//  NULLKIA KOTLIN AUTHENTICATION SYSTEM
//  JVM-based auth with modern Kotlin features
//  @author bad-antics | x.com/AnonAntics
// ═══════════════════════════════════════════════════════════════════

package com.nullsec.nullkia.auth

import java.security.SecureRandom
import java.security.MessageDigest
import java.util.Base64
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import java.time.Instant
import java.time.Duration

const val VERSION = "2.0.0"
const val AUTHOR = "bad-antics"
const val DISCORD = "x.com/AnonAntics"

val BANNER = """
╭──────────────────────────────────────────╮
│      📱 NULLKIA KOTLIN AUTH SYSTEM       │
│      ════════════════════════════        │
│                                          │
│   🔐 PBKDF2 Password Hashing             │
│   🎫 JWT-Style Session Tokens            │
│   👤 Multi-Profile Support               │
│                                          │
│          bad-antics | NullSec            │
╰──────────────────────────────────────────╯
""".trimIndent()

// ═══════════════════════════════════════════════════════════════════
// License Tier Enum
// ═══════════════════════════════════════════════════════════════════

enum class LicenseTier(val displayName: String, val features: List<String>) {
    FREE("Free", listOf("Basic tools", "Community support")),
    PREMIUM("Premium ⭐", listOf("All tools", "Priority support", "Exploit database")),
    ENTERPRISE("Enterprise 💎", listOf("Custom modules", "API access", "Dedicated support"))
}

// ═══════════════════════════════════════════════════════════════════
// Data Classes
// ═══════════════════════════════════════════════════════════════════

data class License(
    val key: String,
    val tier: LicenseTier,
    val valid: Boolean,
    val expiresAt: Instant? = null
)

data class User(
    val id: String,
    val username: String,
    val email: String,
    val passwordHash: String,
    val salt: String,
    val tier: LicenseTier,
    val createdAt: Instant,
    val lastLogin: Instant? = null,
    val profileData: Map<String, Any> = emptyMap()
)

data class Session(
    val token: String,
    val userId: String,
    val createdAt: Instant,
    val expiresAt: Instant,
    val ipAddress: String? = null,
    val userAgent: String? = null
)

data class AuthResult(
    val success: Boolean,
    val message: String,
    val user: User? = null,
    val session: Session? = null
)

// ═══════════════════════════════════════════════════════════════════
// Crypto Utilities
// ═══════════════════════════════════════════════════════════════════

object CryptoUtils {
    private const val PBKDF2_ITERATIONS = 100_000
    private const val KEY_LENGTH = 256
    private const val SALT_LENGTH = 32
    
    private val random = SecureRandom()
    
    fun generateSalt(): String {
        val salt = ByteArray(SALT_LENGTH)
        random.nextBytes(salt)
        return Base64.getEncoder().encodeToString(salt)
    }
    
    fun hashPassword(password: String, salt: String): String {
        val saltBytes = Base64.getDecoder().decode(salt)
        val spec = PBEKeySpec(password.toCharArray(), saltBytes, PBKDF2_ITERATIONS, KEY_LENGTH)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        val hash = factory.generateSecret(spec).encoded
        return Base64.getEncoder().encodeToString(hash)
    }
    
    fun verifyPassword(password: String, hash: String, salt: String): Boolean {
        val newHash = hashPassword(password, salt)
        return newHash == hash
    }
    
    fun generateToken(length: Int = 64): String {
        val bytes = ByteArray(length)
        random.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }
    
    fun generateUserId(): String {
        return "NKIA-${generateToken(8).take(12).uppercase()}"
    }
    
    fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(input.toByteArray())
        return hash.joinToString("") { "%02x".format(it) }
    }
}

// ═══════════════════════════════════════════════════════════════════
// License Validator
// ═══════════════════════════════════════════════════════════════════

object LicenseValidator {
    private val licensePattern = Regex("^NKIA-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$")
    
    fun validate(key: String): License {
        if (!licensePattern.matches(key)) {
            return License(key = "", tier = LicenseTier.FREE, valid = false)
        }
        
        val parts = key.split("-")
        if (parts.size != 5) {
            return License(key = "", tier = LicenseTier.FREE, valid = false)
        }
        
        val tierCode = parts[1].take(2)
        val tier = when (tierCode) {
            "PR" -> LicenseTier.PREMIUM
            "EN" -> LicenseTier.ENTERPRISE
            else -> LicenseTier.FREE
        }
        
        // Check expiration (last segment encodes expiry month/year)
        val expiryCode = parts[4]
        val expiresAt = try {
            val month = expiryCode.take(2).toInt()
            val year = 2024 + expiryCode.drop(2).take(2).toInt()
            Instant.parse("${year}-${month.toString().padStart(2, '0')}-01T00:00:00Z")
        } catch (e: Exception) {
            Instant.now().plus(Duration.ofDays(365))
        }
        
        return License(
            key = key,
            tier = tier,
            valid = true,
            expiresAt = expiresAt
        )
    }
    
    fun isExpired(license: License): Boolean {
        return license.expiresAt?.isBefore(Instant.now()) ?: false
    }
}

// ═══════════════════════════════════════════════════════════════════
// Auth Manager
// ═══════════════════════════════════════════════════════════════════

class AuthManager {
    private val users = mutableMapOf<String, User>()
    private val sessions = mutableMapOf<String, Session>()
    private val usernameIndex = mutableMapOf<String, String>()
    private val emailIndex = mutableMapOf<String, String>()
    
    companion object {
        private const val SESSION_DURATION_HOURS = 24L
        private const val MIN_PASSWORD_LENGTH = 8
    }
    
    fun register(
        username: String,
        email: String,
        password: String,
        licenseKey: String? = null
    ): AuthResult {
        // Validate username
        if (username.length < 3 || username.length > 32) {
            return AuthResult(false, "Username must be 3-32 characters")
        }
        if (!username.matches(Regex("^[a-zA-Z0-9_-]+$"))) {
            return AuthResult(false, "Username contains invalid characters")
        }
        if (usernameIndex.containsKey(username.lowercase())) {
            return AuthResult(false, "Username already exists")
        }
        
        // Validate email
        if (!email.matches(Regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"))) {
            return AuthResult(false, "Invalid email format")
        }
        if (emailIndex.containsKey(email.lowercase())) {
            return AuthResult(false, "Email already registered")
        }
        
        // Validate password
        if (password.length < MIN_PASSWORD_LENGTH) {
            return AuthResult(false, "Password must be at least $MIN_PASSWORD_LENGTH characters")
        }
        
        // Validate license
        val tier = if (licenseKey != null) {
            val license = LicenseValidator.validate(licenseKey)
            if (license.valid && !LicenseValidator.isExpired(license)) {
                license.tier
            } else {
                LicenseTier.FREE
            }
        } else {
            LicenseTier.FREE
        }
        
        // Create user
        val salt = CryptoUtils.generateSalt()
        val passwordHash = CryptoUtils.hashPassword(password, salt)
        val userId = CryptoUtils.generateUserId()
        
        val user = User(
            id = userId,
            username = username,
            email = email,
            passwordHash = passwordHash,
            salt = salt,
            tier = tier,
            createdAt = Instant.now()
        )
        
        // Store user
        users[userId] = user
        usernameIndex[username.lowercase()] = userId
        emailIndex[email.lowercase()] = userId
        
        return AuthResult(
            success = true,
            message = "Registration successful! Welcome to NullKia.",
            user = user.copy(passwordHash = "[HIDDEN]", salt = "[HIDDEN]")
        )
    }
    
    fun login(usernameOrEmail: String, password: String): AuthResult {
        // Find user
        val userId = usernameIndex[usernameOrEmail.lowercase()]
            ?: emailIndex[usernameOrEmail.lowercase()]
            ?: return AuthResult(false, "User not found")
        
        val user = users[userId]
            ?: return AuthResult(false, "User data corrupted")
        
        // Verify password
        if (!CryptoUtils.verifyPassword(password, user.passwordHash, user.salt)) {
            return AuthResult(false, "Invalid password")
        }
        
        // Create session
        val session = Session(
            token = CryptoUtils.generateToken(),
            userId = userId,
            createdAt = Instant.now(),
            expiresAt = Instant.now().plus(Duration.ofHours(SESSION_DURATION_HOURS))
        )
        
        sessions[session.token] = session
        
        // Update last login
        users[userId] = user.copy(lastLogin = Instant.now())
        
        return AuthResult(
            success = true,
            message = "Login successful! Welcome back, ${user.username}.",
            user = user.copy(passwordHash = "[HIDDEN]", salt = "[HIDDEN]"),
            session = session
        )
    }
    
    fun validateSession(token: String): AuthResult {
        val session = sessions[token]
            ?: return AuthResult(false, "Session not found")
        
        if (session.expiresAt.isBefore(Instant.now())) {
            sessions.remove(token)
            return AuthResult(false, "Session expired")
        }
        
        val user = users[session.userId]
            ?: return AuthResult(false, "User not found")
        
        return AuthResult(
            success = true,
            message = "Session valid",
            user = user.copy(passwordHash = "[HIDDEN]", salt = "[HIDDEN]"),
            session = session
        )
    }
    
    fun logout(token: String): AuthResult {
        return if (sessions.remove(token) != null) {
            AuthResult(true, "Logged out successfully")
        } else {
            AuthResult(false, "Session not found")
        }
    }
    
    fun changePassword(userId: String, oldPassword: String, newPassword: String): AuthResult {
        val user = users[userId]
            ?: return AuthResult(false, "User not found")
        
        if (!CryptoUtils.verifyPassword(oldPassword, user.passwordHash, user.salt)) {
            return AuthResult(false, "Current password is incorrect")
        }
        
        if (newPassword.length < MIN_PASSWORD_LENGTH) {
            return AuthResult(false, "New password must be at least $MIN_PASSWORD_LENGTH characters")
        }
        
        val newSalt = CryptoUtils.generateSalt()
        val newHash = CryptoUtils.hashPassword(newPassword, newSalt)
        
        users[userId] = user.copy(
            passwordHash = newHash,
            salt = newSalt
        )
        
        // Invalidate all sessions for this user
        sessions.entries.removeIf { it.value.userId == userId }
        
        return AuthResult(true, "Password changed successfully")
    }
    
    fun upgradeLicense(userId: String, licenseKey: String): AuthResult {
        val user = users[userId]
            ?: return AuthResult(false, "User not found")
        
        val license = LicenseValidator.validate(licenseKey)
        
        if (!license.valid) {
            return AuthResult(false, "Invalid license key")
        }
        
        if (LicenseValidator.isExpired(license)) {
            return AuthResult(false, "License key has expired")
        }
        
        if (license.tier.ordinal <= user.tier.ordinal) {
            return AuthResult(false, "New license is not an upgrade")
        }
        
        users[userId] = user.copy(tier = license.tier)
        
        return AuthResult(
            success = true,
            message = "Upgraded to ${license.tier.displayName}!",
            user = users[userId]?.copy(passwordHash = "[HIDDEN]", salt = "[HIDDEN]")
        )
    }
    
    fun getStats(): Map<String, Any> {
        return mapOf(
            "totalUsers" to users.size,
            "activeSessions" to sessions.count { it.value.expiresAt.isAfter(Instant.now()) },
            "premiumUsers" to users.count { it.value.tier != LicenseTier.FREE },
            "freeUsers" to users.count { it.value.tier == LicenseTier.FREE }
        )
    }
}

// ═══════════════════════════════════════════════════════════════════
// Console UI
// ═══════════════════════════════════════════════════════════════════

object ConsoleUI {
    fun printSuccess(msg: String) = println("\u001b[32m✅ $msg\u001b[0m")
    fun printError(msg: String) = println("\u001b[31m❌ $msg\u001b[0m")
    fun printWarning(msg: String) = println("\u001b[33m⚠️  $msg\u001b[0m")
    fun printInfo(msg: String) = println("\u001b[36mℹ️  $msg\u001b[0m")
    fun printCyan(msg: String) = println("\u001b[36m$msg\u001b[0m")
    
    fun printUser(user: User) {
        println("""
            |  👤 User Profile
            |  ────────────────
            |  ID: ${user.id}
            |  Username: ${user.username}
            |  Email: ${user.email}
            |  Tier: ${user.tier.displayName}
            |  Created: ${user.createdAt}
            |  Last Login: ${user.lastLogin ?: "Never"}
        """.trimMargin())
    }
}

// ═══════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════

fun main(args: Array<String>) {
    println(BANNER)
    println("  Version $VERSION | $AUTHOR")
    println("  🔑 Premium: $DISCORD\n")
    
    val auth = AuthManager()
    
    // Demo registration
    println("═══════════════════════════════════════════")
    println("  📝 DEMO: User Registration")
    println("═══════════════════════════════════════════\n")
    
    val regResult = auth.register(
        username = "demo_user",
        email = "demo@nullsec.dev",
        password = "SecurePass123!",
        licenseKey = null
    )
    
    if (regResult.success) {
        ConsoleUI.printSuccess(regResult.message)
        regResult.user?.let { ConsoleUI.printUser(it) }
    } else {
        ConsoleUI.printError(regResult.message)
    }
    
    // Demo login
    println("\n═══════════════════════════════════════════")
    println("  🔑 DEMO: User Login")
    println("═══════════════════════════════════════════\n")
    
    val loginResult = auth.login("demo_user", "SecurePass123!")
    
    if (loginResult.success) {
        ConsoleUI.printSuccess(loginResult.message)
        println("  🎫 Session Token: ${loginResult.session?.token?.take(32)}...")
    } else {
        ConsoleUI.printError(loginResult.message)
    }
    
    // Demo license upgrade
    println("\n═══════════════════════════════════════════")
    println("  ⬆️  DEMO: License Upgrade")
    println("═══════════════════════════════════════════\n")
    
    loginResult.user?.let { user ->
        val upgradeResult = auth.upgradeLicense(user.id, "NKIA-PR99-TEST-KEY1-0126")
        if (upgradeResult.success) {
            ConsoleUI.printSuccess(upgradeResult.message)
        } else {
            ConsoleUI.printWarning(upgradeResult.message)
            ConsoleUI.printInfo("Get premium keys at: x.com/AnonAntics")
        }
    }
    
    // Print stats
    println("\n═══════════════════════════════════════════")
    println("  📊 System Stats")
    println("═══════════════════════════════════════════\n")
    
    auth.getStats().forEach { (key, value) ->
        println("  $key: $value")
    }
    
    // Footer
    println("\n─────────────────────────────────────────")
    println("  📱 NullKia Kotlin Auth System")
    println("  🔑 Premium: x.com/AnonAntics")
    println("  👤 Author: bad-antics")
    println("─────────────────────────────────────────\n")
}
