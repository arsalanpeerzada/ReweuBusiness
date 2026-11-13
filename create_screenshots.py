import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('play_store_assets', exist_ok=True)

# Colors
BG_DARK = (0, 39, 46)        # #00272E
BG_TEAL = (0, 52, 61)        # #00343D
SURFACE_CARD = (15, 23, 42)  # #0F172A
SURFACE_BG = (248, 250, 252) # #F8FAFC
TEXT_PRIMARY = (255, 255, 255)
TEXT_MUTED = (148, 163, 184) # #94A3B8
BRAND_ACCENT = (0, 168, 181) # Teal
RED_ALERT = (239, 68, 68)    # #EF4444
GREEN_SUCCESS = (16, 185, 129) # #10B981
AMBER_WARN = (245, 158, 11)  # #F59E0B

f_hero = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 52)
f_sub = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 28)
f_card_title = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 32)
f_card_body = ImageFont.truetype('assets/fonts/PlusJakartaSans-Regular.ttf', 24)
f_card_bold = ImageFont.truetype('assets/fonts/PlusJakartaSans-Bold.ttf', 24)
f_small = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 20)

splash_img = Image.open('assets/images/splash_android12.png')
logo_crop = splash_img.crop(splash_img.getbbox())

def create_base_canvas(headline, subtitle):
    w, h = 1080, 2400
    img = Image.new('RGB', (w, h), BG_DARK)
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(h):
        ratio = y / h
        r = int(0 + (0 - 0) * ratio)
        g = int(32 + (55 - 32) * ratio)
        b = int(40 + (65 - 40) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Top Brand Logo
    target_lw = 240
    target_lh = int(logo_crop.size[1] * (target_lw / logo_crop.size[0]))
    resized_logo = logo_crop.resize((target_lw, target_lh), Image.Resampling.LANCZOS)
    img.paste(resized_logo, ((w - target_lw) // 2, 80), resized_logo)

    # Headline
    bbox_h = draw.textbbox((0, 0), headline, font=f_hero)
    hw = bbox_h[2] - bbox_h[0]
    draw.text(((w - hw) // 2, 190), headline, fill=TEXT_PRIMARY, font=f_hero)

    # Subtitle
    bbox_s = draw.textbbox((0, 0), subtitle, font=f_sub)
    sw = bbox_s[2] - bbox_s[0]
    draw.text(((w - sw) // 2, 260), subtitle, fill=TEXT_MUTED, font=f_sub)

    # Phone Frame Container
    frame_x1, frame_y1 = 70, 360
    frame_x2, frame_y2 = 1010, 2350
    # Outer border / glow
    draw.rounded_rectangle([frame_x1 - 4, frame_y1 - 4, frame_x2 + 4, frame_y2 + 4], radius=44, outline=(0, 168, 181), width=2)
    # Phone screen background
    draw.rounded_rectangle([frame_x1, frame_y1, frame_x2, frame_y2], radius=40, fill=(245, 247, 250))

    # Phone Status Bar (mock)
    draw.text((frame_x1 + 45, frame_y1 + 25), "9:41", fill=(30, 41, 59), font=f_card_bold)
    draw.text((frame_x2 - 120, frame_y1 + 25), "5G  100%", fill=(30, 41, 59), font=f_small)

    return img, draw, frame_x1, frame_y1, frame_x2, frame_y2

# -------------------------------------------------------------
# SCREENSHOT 1: Real-Time Incident Feed
# -------------------------------------------------------------
img1, draw1, fx1, fy1, fx2, fy2 = create_base_canvas(
    "LIVE INCIDENT FEED",
    "Monitor low-score reviews and customer alerts in real time"
)
# App Bar
draw1.rectangle([fx1, fy1 + 70, fx2, fy1 + 160], fill=BG_TEAL)
draw1.text((fx1 + 40, fy1 + 95), "Incident Feed", fill=TEXT_PRIMARY, font=f_card_title)
draw1.rounded_rectangle([fx2 - 220, fy1 + 90, fx2 - 30, fy1 + 140], radius=12, fill=(0, 75, 87))
draw1.text((fx2 - 200, fy1 + 102), "Downtown Branch v", fill=TEXT_PRIMARY, font=f_small)

# Filter Tabs (All, Critical, Pending, Resolved)
tabs = [("All (8)", True), ("Critical (3)", False), ("Pending (4)", False), ("Resolved (1)", False)]
tx = fx1 + 30
ty = fy1 + 180
for title, active in tabs:
    tw = 210
    bg_t = BG_TEAL if active else (226, 232, 240)
    fg_t = TEXT_PRIMARY if active else (71, 85, 105)
    draw1.rounded_rectangle([tx, ty, tx + tw, ty + 56], radius=16, fill=bg_t)
    tb = draw1.textbbox((0, 0), title, font=f_small)
    draw1.text((tx + (tw - (tb[2] - tb[0])) // 2, ty + 16), title, fill=fg_t, font=f_small)
    tx += tw + 15

# Incident Cards
incidents = [
    {
        "id": "#INC-1082", "sev": "CRITICAL", "color": RED_ALERT, "time": "2 mins ago",
        "cust": "Farhan Ahmed", "rating": "★ 1.0 (Food Quality)",
        "desc": "Ordered the family platter, food arrived completely cold and sauces were missing.",
        "action": "Acknowledge"
    },
    {
        "id": "#INC-1081", "sev": "HIGH", "color": AMBER_WARN, "time": "15 mins ago",
        "cust": "Sara Malik", "rating": "★ 2.0 (Delayed Delivery)",
        "desc": "Delivery took 75 minutes. The driver was polite but the meal was late for our meeting.",
        "action": "In Progress"
    },
    {
        "id": "#INC-1079", "sev": "RESOLVED", "color": GREEN_SUCCESS, "time": "1 hour ago",
        "cust": "Usman Tariq", "rating": "★ 5.0 (Resolved with Voucher)",
        "desc": "Branch manager called promptly and offered a PKR 1,500 recovery voucher. Happy!",
        "action": "Resolved"
    }
]

cy = fy1 + 260
for inc in incidents:
    draw1.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 340], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    # Header row
    draw1.text((fx1 + 60, cy + 30), inc["id"], fill=(15, 23, 42), font=f_card_bold)
    draw1.rounded_rectangle([fx1 + 220, cy + 26, fx1 + 370, cy + 66], radius=10, fill=inc["color"])
    draw1.text((fx1 + 235, cy + 32), inc["sev"], fill=(255, 255, 255), font=f_small)
    draw1.text((fx2 - 200, cy + 30), inc["time"], fill=TEXT_MUTED, font=f_small)

    # Customer & Rating
    draw1.text((fx1 + 60, cy + 90), inc["cust"], fill=(30, 41, 59), font=f_card_bold)
    draw1.text((fx1 + 60, cy + 130), inc["rating"], fill=inc["color"], font=f_card_bold)

    # Description
    draw1.text((fx1 + 60, cy + 175), inc["desc"][:58] + "...", fill=(71, 85, 105), font=f_card_body)

    # Action button
    draw1.rounded_rectangle([fx2 - 250, cy + 245, fx2 - 60, cy + 310], radius=16, fill=BG_TEAL)
    draw1.text((fx2 - 225, cy + 262), inc["action"], fill=(255, 255, 255), font=f_small)

    cy += 370

img1.save('play_store_assets/screenshot_1_feed.png', 'PNG', optimize=True)

# -------------------------------------------------------------
# SCREENSHOT 2: Customer Contact & Triage
# -------------------------------------------------------------
img2, draw2, fx1, fy1, fx2, fy2 = create_base_canvas(
    "RAPID INCIDENT TRIAGE",
    "Reach out instantly via Direct Call, WhatsApp, or Email"
)
draw2.rectangle([fx1, fy1 + 70, fx2, fy1 + 160], fill=BG_TEAL)
draw2.text((fx1 + 40, fy1 + 95), "<  Incident #INC-1082", fill=TEXT_PRIMARY, font=f_card_title)

# Customer Info Card
cy = fy1 + 190
draw2.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 320], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw2.text((fx1 + 60, cy + 30), "CUSTOMER PROFILE", fill=TEXT_MUTED, font=f_small)
draw2.text((fx1 + 60, cy + 70), "Farhan Ahmed", fill=(15, 23, 42), font=f_card_title)
draw2.text((fx1 + 60, cy + 120), "+92 300 1234567 • farhan@example.com", fill=(71, 85, 105), font=f_card_body)
draw2.text((fx1 + 60, cy + 160), "Loyalty Tier: Gold Member (18 Orders)", fill=BRAND_ACCENT, font=f_small)

# Quick Action Buttons
btn_w = 260
bx = fx1 + 60
by = cy + 215
actions = [("📞 Direct Call", (37, 99, 235)), ("💬 WhatsApp", (34, 197, 94)), ("✉️ Send Email", (100, 116, 139))]
for label, col in actions:
    draw2.rounded_rectangle([bx, by, bx + btn_w, by + 70], radius=16, fill=col)
    bbox = draw2.textbbox((0, 0), label, font=f_card_bold)
    draw2.text((bx + (btn_w - (bbox[2] - bbox[0])) // 2, by + 20), label, fill=(255, 255, 255), font=f_card_bold)
    bx += btn_w + 30

# Feedback Card
cy += 350
draw2.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 420], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw2.text((fx1 + 60, cy + 30), "CUSTOMER FEEDBACK", fill=TEXT_MUTED, font=f_small)
draw2.text((fx1 + 60, cy + 70), "Rating: ★ 1.0 (Severe Dissatisfaction)", fill=RED_ALERT, font=f_card_bold)
draw2.text((fx1 + 60, cy + 120), "Order #48921 • Delivery • 2 Items", fill=(100, 116, 139), font=f_small)
draw2.rounded_rectangle([fx1 + 60, cy + 170, fx2 - 60, cy + 370], radius=16, fill=(248, 250, 252))
draw2.text((fx1 + 80, cy + 190), "\"Ordered the family platter, food arrived completely cold\nand the specialty dipping sauces were missing.\nWe had guests over and it was embarrassing.\"", fill=(51, 65, 85), font=f_card_body)

# Internal Team Notes Card
cy += 450
draw2.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 380], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw2.text((fx1 + 60, cy + 30), "INTERNAL TIMELINE & NOTES", fill=TEXT_MUTED, font=f_small)
draw2.text((fx1 + 60, cy + 80), "• 10:14 AM - Incident automatically raised from 1★ survey", fill=(71, 85, 105), font=f_card_body)
draw2.text((fx1 + 60, cy + 130), "• 10:16 AM - Acknowledged by Manager (Ali Khan)", fill=(71, 85, 105), font=f_card_body)
draw2.text((fx1 + 60, cy + 180), "• 10:20 AM - Rider dispatched with fresh order + apology", fill=GREEN_SUCCESS, font=f_card_bold)

img2.save('play_store_assets/screenshot_2_triage.png', 'PNG', optimize=True)

# -------------------------------------------------------------
# SCREENSHOT 3: Service Recovery Vouchers
# -------------------------------------------------------------
img3, draw3, fx1, fy1, fx2, fy2 = create_base_canvas(
    "SERVICE RECOVERY VOUCHERS",
    "Resolve incidents & issue instant compensation vouchers"
)
draw3.rectangle([fx1, fy1 + 70, fx2, fy1 + 160], fill=BG_TEAL)
draw3.text((fx1 + 40, fy1 + 95), "Resolve & Customer Recovery", fill=TEXT_PRIMARY, font=f_card_title)

# Voucher Modal Preview
cy = fy1 + 200
draw3.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 1100], radius=28, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw3.text((fx1 + 60, cy + 40), "Resolution Outcome", fill=(15, 23, 42), font=f_card_title)

# Status selector
draw3.rounded_rectangle([fx1 + 60, cy + 100, fx1 + 440, cy + 180], radius=16, fill=(236, 253, 245), outline=GREEN_SUCCESS, width=2)
draw3.text((fx1 + 90, cy + 125), "✓ Resolved Satisfactorily", fill=GREEN_SUCCESS, font=f_card_bold)

draw3.rounded_rectangle([fx1 + 480, cy + 100, fx2 - 60, cy + 180], radius=16, fill=(248, 250, 252), outline=(203, 213, 225), width=1)
draw3.text((fx1 + 510, cy + 125), "Mark Acknowledged", fill=(100, 116, 139), font=f_card_bold)

# Voucher Section
draw3.text((fx1 + 60, cy + 220), "Issue Recovery Voucher (Optional)", fill=(15, 23, 42), font=f_card_bold)
draw3.rounded_rectangle([fx1 + 60, cy + 270, fx2 - 60, cy + 480], radius=20, fill=(240, 253, 250), outline=BRAND_ACCENT, width=2)
draw3.text((fx1 + 90, cy + 300), "Voucher Amount", fill=(15, 23, 42), font=f_card_bold)
draw3.text((fx1 + 90, cy + 350), "PKR 1,500", fill=BG_TEAL, font=f_hero)
draw3.text((fx1 + 90, cy + 420), "Auto-sent to customer SMS & Reweu Wallet", fill=BRAND_ACCENT, font=f_small)

# Resolution Summary Input Box
draw3.text((fx1 + 60, cy + 520), "Resolution Summary", fill=(15, 23, 42), font=f_card_bold)
draw3.rounded_rectangle([fx1 + 60, cy + 570, fx2 - 60, cy + 850], radius=20, fill=(248, 250, 252), outline=(203, 213, 225), width=2)
draw3.text((fx1 + 90, cy + 600), "Spoke with Mr. Farhan on call. Apologised for the cold\nfood and missing sauces. Replaced the order with our\nexpress delivery and issued a PKR 1,500 goodwill\nvoucher for his next dinner. Customer confirmed satisfaction.", fill=(51, 65, 85), font=f_card_body)
draw3.text((fx2 - 200, cy + 805), "248 / 500 chars", fill=TEXT_MUTED, font=f_small)

# Submit button
draw3.rounded_rectangle([fx1 + 60, cy + 900, fx2 - 60, cy + 1020], radius=24, fill=BG_TEAL)
draw3.text((fx1 + 220, cy + 945), "Confirm & Close Incident", fill=(255, 255, 255), font=f_card_title)

img3.save('play_store_assets/screenshot_3_recovery.png', 'PNG', optimize=True)

# -------------------------------------------------------------
# SCREENSHOT 4: Multi-Branch Analytics
# -------------------------------------------------------------
img4, draw4, fx1, fy1, fx2, fy2 = create_base_canvas(
    "MULTI-BRANCH ANALYTICS",
    "Track incident KPIs, resolution rates, and team performance"
)
draw4.rectangle([fx1, fy1 + 70, fx2, fy1 + 160], fill=BG_TEAL)
draw4.text((fx1 + 40, fy1 + 95), "Analytics & Performance", fill=TEXT_PRIMARY, font=f_card_title)

# KPI Cards Row
cy = fy1 + 190
kpis = [
    ("48", "Total Incidents", RED_ALERT),
    ("96%", "Resolution Rate", GREEN_SUCCESS),
    ("11m", "Avg Review Time", BRAND_ACCENT)
]
kw = 260
kx = fx1 + 30
for val, lbl, col in kpis:
    draw4.rounded_rectangle([kx, cy, kx + kw, cy + 180], radius=20, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw4.text((kx + 30, cy + 30), val, fill=col, font=f_hero)
    draw4.text((kx + 30, cy + 115), lbl, fill=(100, 116, 139), font=f_small)
    kx += kw + 30

# Trend Chart Card
cy += 220
draw4.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 420], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw4.text((fx1 + 60, cy + 30), "INCIDENT SEVERITY TREND (LAST 7 DAYS)", fill=TEXT_MUTED, font=f_small)
# Bar chart mock
days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
heights = [120, 80, 160, 95, 210, 140, 70]
bx = fx1 + 80
for d, h_val in zip(days, heights):
    draw4.rounded_rectangle([bx, cy + 330 - h_val, bx + 65, cy + 330], radius=8, fill=BG_TEAL)
    draw4.text((bx + 10, cy + 345), d, fill=(100, 116, 139), font=f_small)
    bx += 115

# Branch Performance Leaderboard
cy += 460
draw4.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 500], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw4.text((fx1 + 60, cy + 30), "BRANCH PERFORMANCE", fill=TEXT_MUTED, font=f_small)

branches = [
    ("Downtown Flagship", "24 Incidents", "98% Resolved", GREEN_SUCCESS),
    ("Mall of Lahore", "14 Incidents", "94% Resolved", GREEN_SUCCESS),
    ("DHA Phase 5", "7 Incidents", "88% Resolved", AMBER_WARN),
    ("Gulberg Express", "3 Incidents", "100% Resolved", GREEN_SUCCESS)
]
by = cy + 80
for name, cnt, res, col in branches:
    draw4.text((fx1 + 60, by), name, fill=(15, 23, 42), font=f_card_bold)
    draw4.text((fx1 + 60, by + 35), cnt, fill=TEXT_MUTED, font=f_small)
    draw4.rounded_rectangle([fx2 - 240, by + 5, fx2 - 60, by + 55], radius=12, fill=(240, 253, 250), outline=col, width=1)
    draw4.text((fx2 - 220, by + 16), res, fill=col, font=f_small)
    by += 95

img4.save('play_store_assets/screenshot_4_analytics.png', 'PNG', optimize=True)

# -------------------------------------------------------------
# SCREENSHOT 5: Biometrics & Security
# -------------------------------------------------------------
img5, draw5, fx1, fy1, fx2, fy2 = create_base_canvas(
    "ENTERPRISE SECURITY",
    "Biometric authentication & customer privacy protection"
)
draw5.rectangle([fx1, fy1 + 70, fx2, fy1 + 160], fill=BG_TEAL)
draw5.text((fx1 + 40, fy1 + 95), "Security & Preferences", fill=TEXT_PRIMARY, font=f_card_title)

# Lock / Biometric Card
cy = fy1 + 220
draw5.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 450], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
# Biometric Icon circle
draw5.ellipse([fx1 + 370, cy + 50, fx1 + 530, cy + 210], fill=(236, 253, 245), outline=GREEN_SUCCESS, width=3)
draw5.text((fx1 + 420, cy + 95), "🔒", font=f_hero)
draw5.text((fx1 + 270, cy + 240), "Biometric App Lock", fill=(15, 23, 42), font=f_card_title)
draw5.text((fx1 + 160, cy + 300), "Unlock securely with Fingerprint, Face ID or PIN", fill=(71, 85, 105), font=f_card_body)
draw5.rounded_rectangle([fx1 + 250, cy + 360, fx2 - 250, cy + 420], radius=16, fill=GREEN_SUCCESS)
draw5.text((fx1 + 330, cy + 375), "✓ Active & Protected", fill=(255, 255, 255), font=f_card_bold)

# Privacy & Compliance Card
cy += 490
draw5.rounded_rectangle([fx1 + 30, cy, fx2 - 30, cy + 620], radius=24, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
draw5.text((fx1 + 60, cy + 40), "PRIVACY & PROTECTION FEATURES", fill=TEXT_MUTED, font=f_small)

features = [
    ("🛡️ Screen Protection (FLAG_SECURE)", "Screenshots & screen recording are blocked on customer detail screens"),
    ("⚡ Offline-First Architecture", "Cached incident feed with end-to-end encrypted local storage"),
    ("🌐 Dual-Language Support", "Seamlessly toggle between English and Urdu (Nastaliq RTL)"),
    ("🔔 Critical Sound Alerts", "High-priority push notifications ensure zero missed incidents")
]

fy = cy + 100
for title, desc in features:
    draw5.text((fx1 + 60, fy), title, fill=(15, 23, 42), font=f_card_bold)
    draw5.text((fx1 + 60, fy + 40), desc, fill=(71, 85, 105), font=f_card_body)
    fy += 125

img5.save('play_store_assets/screenshot_5_security.png', 'PNG', optimize=True)

print("All 5 phone screenshots created successfully in play_store_assets/")
