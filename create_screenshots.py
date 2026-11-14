import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('play_store_assets', exist_ok=True)

# Brand & UI Palette
BG_TOP = (0, 36, 43)           # Deep dark teal
BG_BOTTOM = (0, 56, 66)        # Rich brand teal #003842
BRAND_TEAL = (0, 52, 61)       # #00343D
BRAND_GOLD = (255, 165, 2)     # #FFA502
BRAND_CYAN = (0, 168, 181)     # #00A8B5
SCREEN_BG = (244, 246, 249)    # #F4F6F9
CARD_WHITE = (255, 255, 255)
BORDER_LIGHT = (226, 232, 240)
TEXT_DARK = (15, 23, 42)       # #0F172A
TEXT_SLATE = (71, 85, 105)     # #475569
TEXT_MUTED = (148, 163, 184)   # #94A3B8
TEXT_WHITE = (255, 255, 255)

RED_CRIT = (220, 38, 38)       # #DC2626
RED_BG = (254, 242, 242)
AMBER_HIGH = (217, 119, 6)     # #D97706
AMBER_BG = (255, 251, 235)
GREEN_OK = (5, 150, 105)       # #059669
GREEN_BG = (236, 253, 245)

# Fonts (1:1 native 1080x1920 — never resized!)
f_headline = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 46)
f_subtitle = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 23)
f_appbar = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 26)
f_h1 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 34)
f_h2 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 22)
f_bold = ImageFont.truetype('assets/fonts/PlusJakartaSans-Bold.ttf', 19)
f_semi = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 18)
f_body = ImageFont.truetype('assets/fonts/PlusJakartaSans-Regular.ttf', 17)
f_small = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 15)
f_tiny = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 13)

logo_raw = Image.open('assets/images/logo.png').convert('RGBA')
logo_crop = logo_raw.crop(logo_raw.getbbox()) # (700, 218)


def draw_centered_text(draw, y, text, font, fill, center_x=540):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((center_x - tw // 2, y), text, fill=fill, font=font)


def create_phone_canvas(headline, subtitle, active_nav=0, show_bottom_nav=True):
    """Creates a native 1080x1920 (exact 9:16) marketing canvas with a slender 9:19.5 smartphone frame."""
    W, H = 1080, 1920
    img = Image.new('RGB', (W, H), BG_TOP)
    draw = ImageDraw.Draw(img)

    # Vertical background gradient
    for y in range(H):
        ratio = y / H
        r = 0
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * ratio)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Brand Logo at Top (true aspect ratio)
    lw = 220
    lh = int(logo_crop.size[1] * (lw / logo_crop.size[0]))
    logo_sm = logo_crop.resize((lw, lh), Image.Resampling.LANCZOS)
    img.paste(logo_sm, ((W - lw) // 2, 52), logo_sm)

    # Headline & Subtitle
    draw_centered_text(draw, 145, headline, f_headline, TEXT_WHITE)
    draw_centered_text(draw, 206, subtitle, f_subtitle, (203, 213, 225))

    # Slender Smartphone Frame (660 x 1540 -> aspect ratio ~9:21 like Pixel 8 / iPhone 15)
    # Leaves 210px margin on left and 210px on right so it unmistakably looks like a mobile handset
    px1, py1 = 210, 275
    px2, py2 = 870, 1845

    # Side hardware buttons on right edge of phone chassis
    draw.rounded_rectangle([px2 - 2, py1 + 260, px2 + 7, py1 + 340], radius=3, fill=(60, 75, 85))
    draw.rounded_rectangle([px2 - 2, py1 + 380, px2 + 7, py1 + 510], radius=3, fill=(60, 75, 85))

    # Outer metallic rim + dark bezel
    draw.rounded_rectangle([px1 - 4, py1 - 4, px2 + 4, py2 + 4], radius=68, fill=(51, 65, 85), outline=(100, 116, 139), width=2)
    draw.rounded_rectangle([px1, py1, px2, py2], radius=64, fill=(15, 23, 42))

    # Inner display area (16px bezel)
    sx1, sy1 = px1 + 16, py1 + 16
    sx2, sy2 = px2 - 16, py2 - 16
    draw.rounded_rectangle([sx1, sy1, sx2, sy2], radius=50, fill=SCREEN_BG)

    # Top status bar inside phone screen
    draw.rounded_rectangle([sx1, sy1, sx2, sy1 + 135], radius=50, fill=BRAND_TEAL)
    draw.rectangle([sx1, sy1 + 50, sx2, sy1 + 135], fill=BRAND_TEAL)

    # Punch-hole front camera centered at top of phone screen
    cam_r = 11
    draw.ellipse([540 - cam_r, sy1 + 16, 540 + cam_r, sy1 + 16 + cam_r * 2], fill=(10, 15, 28))

    # Clock & status icons
    draw.text((sx1 + 34, sy1 + 16), "9:41", fill=TEXT_WHITE, font=f_small)
    draw.text((sx2 - 105, sy1 + 16), "5G  100%", fill=TEXT_WHITE, font=f_tiny)

    # Bottom navigation bar + gesture pill
    if show_bottom_nav:
        nav_y = sy2 - 92
        draw.rounded_rectangle([sx1, nav_y, sx2, sy2], radius=50, fill=CARD_WHITE)
        draw.rectangle([sx1, nav_y, sx2, nav_y + 45], fill=CARD_WHITE)
        draw.line([(sx1, nav_y), (sx2, nav_y)], fill=BORDER_LIGHT, width=2)

        nav_items = ["Incidents", "Analytics", "Profile"]
        col_w = (sx2 - sx1) // 3
        for idx, label in enumerate(nav_items):
            cx = sx1 + idx * col_w + col_w // 2
            is_act = (idx == active_nav)
            pill_col = (224, 242, 241) if is_act else CARD_WHITE
            txt_col = BRAND_TEAL if is_act else TEXT_MUTED
            if is_act:
                draw.rounded_rectangle([cx - 52, nav_y + 10, cx + 52, nav_y + 38], radius=14, fill=pill_col)
            draw_centered_text(draw, nav_y + 14, label, f_small if is_act else f_tiny, txt_col, center_x=cx)

    # Android/iOS home gesture bar at bottom of screen
    draw.rounded_rectangle([540 - 75, sy2 - 14, 540 + 75, sy2 - 8], radius=3, fill=(148, 163, 184))

    return img, draw, sx1, sy1, sx2, sy2


# ==============================================================================
# SCREENSHOT 1: Real-Time Incident Feed
# ==============================================================================
img1, d1, sx1, sy1, sx2, sy2 = create_phone_canvas(
    "REAL-TIME INCIDENT FEED",
    "Catch low-scoring customer reviews the moment they happen",
    active_nav=0
)

# App Bar content
d1.text((sx1 + 26, sy1 + 58), "Reweu Partners", fill=TEXT_WHITE, font=f_appbar)
d1.rounded_rectangle([sx2 - 185, sy1 + 56, sx2 - 22, sy1 + 96], radius=12, fill=(0, 76, 89), outline=(0, 120, 138), width=1)
d1.text((sx2 - 170, sy1 + 67), "All Branches  v", fill=TEXT_WHITE, font=f_tiny)

# Search Bar
cy = sy1 + 150
d1.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 48], radius=14, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d1.text((sx1 + 40, cy + 14), "Search customer, order # or branch...", fill=TEXT_MUTED, font=f_tiny)

# Filter Chips
cy += 64
chips = [("All (12)", True), ("Critical (3)", False), ("Open (5)", False), ("Resolved (4)", False)]
cx = sx1 + 20
for label, active in chips:
    bbox = d1.textbbox((0, 0), label, font=f_tiny)
    cw = (bbox[2] - bbox[0]) + 32
    bg = BRAND_TEAL if active else CARD_WHITE
    fg = TEXT_WHITE if active else TEXT_SLATE
    d1.rounded_rectangle([cx, cy, cx + cw, cy + 38], radius=19, fill=bg, outline=BRAND_TEAL if active else BORDER_LIGHT, width=1)
    d1.text((cx + 16, cy + 10), label, fill=fg, font=f_tiny)
    cx += cw + 10

# 4 Compact Phone Incident Cards
cards = [
    {
        "id": "#INC-1082", "branch": "Downtown Branch", "time": "2m ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Farhan Ahmed", "rating": "1.0 ★  Food Quality",
        "comment": "\"Ordered the family platter, food arrived cold and dipping sauces were missing.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    },
    {
        "id": "#INC-1081", "branch": "Gulberg Flagship", "time": "14m ago",
        "sev": "HIGH", "sev_fg": AMBER_HIGH, "sev_bg": AMBER_BG,
        "cust": "Sara Malik", "rating": "2.0 ★  Slow Service",
        "comment": "\"Waited 40 minutes for table service during lunch hour. Staff seemed overwhelmed.\"",
        "status": "In Review", "btn_bg": (224, 242, 241), "btn_fg": BRAND_TEAL
    },
    {
        "id": "#INC-1079", "branch": "DHA Phase 5", "time": "48m ago",
        "sev": "RESOLVED", "sev_fg": GREEN_OK, "sev_bg": GREEN_BG,
        "cust": "Usman Tariq", "rating": "1.0 ★  Recovered (PKR 1,500 Voucher)",
        "comment": "\"Manager called within 5 minutes, apologized and issued a recovery voucher.\"",
        "status": "Resolved", "btn_bg": GREEN_BG, "btn_fg": GREEN_OK
    },
    {
        "id": "#INC-1076", "branch": "Mall Road Outlet", "time": "2h ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Ayesha Siddiqui", "rating": "1.0 ★  Wrong Order Item",
        "comment": "\"Received spicy chicken instead of mild kids meal. Needs immediate replacement.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    }
]

cy += 54
for c in cards:
    ch = 248
    d1.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + ch], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
    # Left severity accent bar
    d1.rounded_rectangle([sx1 + 20, cy + 16, sx1 + 26, cy + ch - 16], radius=3, fill=c["sev_fg"])

    # Row 1: ID + Branch + Severity Badge
    d1.text((sx1 + 42, cy + 18), f"{c['id']}  •  {c['branch']}", fill=TEXT_SLATE, font=f_tiny)
    d1.rounded_rectangle([sx2 - 135, cy + 14, sx2 - 36, cy + 40], radius=8, fill=c["sev_bg"])
    draw_centered_text(d1, cy + 19, c["sev"], f_tiny, c["sev_fg"], center_x=sx2 - 85)

    # Row 2: Customer Name & Time
    d1.text((sx1 + 42, cy + 48), c["cust"], fill=TEXT_DARK, font=f_bold)
    d1.text((sx2 - 95, cy + 50), c["time"], fill=TEXT_MUTED, font=f_tiny)

    # Row 3: Rating
    d1.text((sx1 + 42, cy + 78), c["rating"], fill=c["sev_fg"], font=f_small)

    # Row 4: Comment snippet (2 lines)
    words = c["comment"].split()
    line1 = " ".join(words[:8])
    line2 = " ".join(words[8:])
    d1.text((sx1 + 42, cy + 108), line1, fill=TEXT_SLATE, font=f_body)
    d1.text((sx1 + 42, cy + 132), line2, fill=TEXT_SLATE, font=f_body)

    # Row 5: Action Footer
    d1.line([(sx1 + 42, cy + 174), (sx2 - 36, cy + 174)], fill=(241, 245, 249), width=1)
    d1.text((sx1 + 42, cy + 194), "Tap to view timeline & contact", fill=TEXT_MUTED, font=f_tiny)
    d1.rounded_rectangle([sx2 - 165, cy + 186, sx2 - 36, cy + 230], radius=12, fill=c["btn_bg"])
    draw_centered_text(d1, cy + 198, c["status"], f_small, c["btn_fg"], center_x=sx2 - 100)

    cy += ch + 16

img1.save('play_store_assets/screenshot_1_feed.png', 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 2: Rapid Customer Triage & Contact
# ==============================================================================
img2, d2, sx1, sy1, sx2, sy2 = create_phone_canvas(
    "INSTANT CUSTOMER TRIAGE",
    "Call, WhatsApp, or email dissatisfied guests in one tap",
    active_nav=0
)

d2.text((sx1 + 26, sy1 + 58), "←  Incident #INC-1082", fill=TEXT_WHITE, font=f_appbar)
d2.rounded_rectangle([sx2 - 130, sy1 + 58, sx2 - 24, sy1 + 92], radius=10, fill=RED_CRIT)
draw_centered_text(d2, sy1 + 66, "CRITICAL", f_tiny, TEXT_WHITE, center_x=sx2 - 77)

cy = sy1 + 150
# Card 1: Customer Contact Card
d2.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 270], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 40, cy + 20), "CUSTOMER DETAILS", fill=TEXT_MUTED, font=f_tiny)
d2.text((sx1 + 40, cy + 48), "Farhan Ahmed", fill=TEXT_DARK, font=f_h2)
d2.text((sx1 + 40, cy + 82), "+92 300 8492011  •  farhan.a@gmail.com", fill=TEXT_SLATE, font=f_body)
d2.text((sx1 + 40, cy + 112), "Branch: Downtown Branch  •  Table / Order #4892", fill=BRAND_CYAN, font=f_small)

# 3 Contact Hand-off Buttons
btns = [
    ("Call Guest", (37, 99, 235)),
    ("WhatsApp", (22, 163, 74)),
    ("Send Email", (71, 85, 105))
]
bw = 175
bx = sx1 + 40
for label, col in btns:
    d2.rounded_rectangle([bx, cy + 155, bx + bw, cy + 210], radius=14, fill=col)
    draw_centered_text(d2, cy + 172, label, f_small, TEXT_WHITE, center_x=bx + bw // 2)
    bx += bw + 22

d2.text((sx1 + 40, cy + 228), "Protected: Screenshots & recording blocked on this screen", fill=TEXT_MUTED, font=f_tiny)

# Card 2: Review & Feedback Breakdown
cy += 290
d2.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 310], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 40, cy + 20), "LOW-SCORE REVIEW TRIGGER", fill=TEXT_MUTED, font=f_tiny)
d2.text((sx1 + 40, cy + 48), "★ 1.0 / 5.0  —  Food Quality & Accuracy", fill=RED_CRIT, font=f_bold)
d2.rounded_rectangle([sx1 + 40, cy + 88, sx2 - 40, cy + 215], radius=14, fill=SCREEN_BG)
d2.text((sx1 + 58, cy + 104), "\"Ordered the family platter for our dinner guests.", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 58, cy + 132), "The food arrived completely cold and all specialty", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 58, cy + 160), "dipping sauces were missing from the bag.\"", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 40, cy + 235), "Staff on Duty: Bilal H. (Shift Supervisor)", fill=TEXT_SLATE, font=f_small)
d2.text((sx1 + 40, cy + 265), "SLA Timer: Respond within 15 mins (11m remaining)", fill=AMBER_HIGH, font=f_small)

# Card 3: Internal Team Notes & Audit Trail
cy += 330
d2.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 430], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 40, cy + 20), "INTERNAL NOTES & AUDIT TIMELINE", fill=TEXT_MUTED, font=f_tiny)

timeline = [
    ("10:14 AM  —  Incident raised from 1★ customer review", "Automatically assigned to Downtown Branch", TEXT_SLATE),
    ("10:16 AM  —  Acknowledged by Branch Manager", "Ali Raza took ownership of this incident", BRAND_TEAL),
    ("10:19 AM  —  Team Note Added", "Called guest, apologized & dispatched hot replacement", GREEN_OK)
]
ty = cy + 56
for line_top, line_sub, col in timeline:
    d2.ellipse([sx1 + 40, ty + 4, sx1 + 54, ty + 18], fill=col)
    d2.text((sx1 + 68, ty), line_top, fill=TEXT_DARK, font=f_small)
    d2.text((sx1 + 68, ty + 23), line_sub, fill=TEXT_SLATE, font=f_tiny)
    ty += 62

# Add Note Input with 500 char limit
d2.rounded_rectangle([sx1 + 40, cy + 245, sx2 - 40, cy + 335], radius=12, fill=SCREEN_BG, outline=BORDER_LIGHT, width=1)
d2.text((sx1 + 56, cy + 260), "Add internal triage note for staff...", fill=TEXT_MUTED, font=f_body)
d2.text((sx2 - 130, cy + 305), "0 / 500 chars", fill=TEXT_MUTED, font=f_tiny)

# Resolve CTA Button
d2.rounded_rectangle([sx1 + 40, cy + 355, sx2 - 40, cy + 412], radius=14, fill=BRAND_TEAL)
draw_centered_text(d2, cy + 371, "Resolve Incident & Issue Voucher", f_bold, TEXT_WHITE)

img2.save('play_store_assets/screenshot_2_triage.png', 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 3: Service Recovery Vouchers
# ==============================================================================
img3, d3, sx1, sy1, sx2, sy2 = create_phone_canvas(
    "SERVICE RECOVERY VOUCHERS",
    "Turn unhappy guests into loyal regulars with instant vouchers",
    active_nav=0
)

d3.text((sx1 + 26, sy1 + 58), "Resolve Incident #INC-1082", fill=TEXT_WHITE, font=f_appbar)

cy = sy1 + 150
d3.rounded_rectangle([sx1 + 20, cy, sx2 - 20, sy2 - 110], radius=22, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)

d3.text((sx1 + 42, cy + 28), "1. Select Resolution Status", fill=TEXT_DARK, font=f_h2)
# Status radio cards
d3.rounded_rectangle([sx1 + 42, cy + 72, sx1 + 315, cy + 145], radius=14, fill=GREEN_BG, outline=GREEN_OK, width=2)
d3.text((sx1 + 62, cy + 88), "Resolved (Selected)", fill=GREEN_OK, font=f_bold)
d3.text((sx1 + 62, cy + 114), "Issue fixed with customer", fill=GREEN_OK, font=f_tiny)

d3.rounded_rectangle([sx1 + 335, cy + 72, sx2 - 42, cy + 145], radius=14, fill=SCREEN_BG, outline=BORDER_LIGHT, width=1)
d3.text((sx1 + 355, cy + 88), "Acknowledged", fill=TEXT_SLATE, font=f_bold)
d3.text((sx1 + 355, cy + 114), "Under investigation", fill=TEXT_MUTED, font=f_tiny)

# Voucher Toggle & Price Input (PKR 50,000 limit enforced)
d3.text((sx1 + 42, cy + 178), "2. Service Recovery Voucher", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([sx1 + 42, cy + 220, sx2 - 42, cy + 445], radius=18, fill=(240, 253, 250), outline=BRAND_CYAN, width=2)
d3.text((sx1 + 64, cy + 242), "Attach Goodwill Compensation Voucher", fill=BRAND_TEAL, font=f_bold)
d3.rounded_rectangle([sx2 - 125, cy + 238, sx2 - 64, cy + 270], radius=16, fill=GREEN_OK)
d3.ellipse([sx2 - 92, cy + 242, sx2 - 68, cy + 266], fill=TEXT_WHITE)

d3.text((sx1 + 64, cy + 288), "Voucher Amount (PKR)  •  Max Limit: PKR 50,000", fill=TEXT_SLATE, font=f_tiny)
d3.rounded_rectangle([sx1 + 64, cy + 316, sx2 - 64, cy + 382], radius=12, fill=CARD_WHITE, outline=BRAND_TEAL, width=2)
d3.text((sx1 + 84, cy + 332), "PKR  1,500", fill=BRAND_TEAL, font=f_appbar)
d3.text((sx2 - 185, cy + 340), "Valid for 30 days", fill=GREEN_OK, font=f_tiny)
d3.text((sx1 + 64, cy + 400), "Voucher code is sent automatically to customer upon resolution", fill=BRAND_TEAL, font=f_tiny)

# Top-aligned Resolution Summary Box (500 character limit)
d3.text((sx1 + 42, cy + 478), "3. Resolution Summary (Required)", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([sx1 + 42, cy + 520, sx2 - 42, cy + 790], radius=16, fill=SCREEN_BG, outline=BORDER_LIGHT, width=2)
summary_lines = [
    "Spoke with Mr. Farhan directly on phone and apologized",
    "for the cold platter and missing sauces.",
    "",
    "Dispatched a fresh hot replacement order via express",
    "rider and issued a PKR 1,500 recovery voucher for his",
    "next family visit. Customer was very appreciative."
]
sy_text = cy + 540
for line in summary_lines:
    d3.text((sx1 + 62, sy_text), line, fill=TEXT_DARK, font=f_body)
    sy_text += 28

d3.text((sx2 - 160, cy + 755), "242 / 500 chars", fill=TEXT_MUTED, font=f_tiny)

# Confirm Button
d3.rounded_rectangle([sx1 + 42, cy + 830, sx2 - 42, cy + 898], radius=16, fill=BRAND_TEAL)
draw_centered_text(d3, cy + 851, "Confirm Resolution & Send Voucher", f_bold, TEXT_WHITE)

img3.save('play_store_assets/screenshot_3_recovery.png', 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 4: Multi-Branch & Staff Analytics
# ==============================================================================
img4, d4, sx1, sy1, sx2, sy2 = create_phone_canvas(
    "BRANCH & STAFF ANALYTICS",
    "Track resolution speed, incident trends, and location performance",
    active_nav=1
)

d4.text((sx1 + 26, sy1 + 58), "Performance Analytics", fill=TEXT_WHITE, font=f_appbar)
# Period selector pills
periods = [("7 Days", False), ("30 Days", True), ("90 Days", False)]
px = sx2 - 235
for p_lbl, act in periods:
    d4.rounded_rectangle([px, sy1 + 60, px + 68, sy1 + 90], radius=10, fill=BRAND_GOLD if act else (0, 76, 89))
    draw_centered_text(d4, sy1 + 67, p_lbl, f_tiny, TEXT_DARK if act else TEXT_WHITE, center_x=px + 34)
    px += 74

cy = sy1 + 150
# 2x2 KPI Grid
kpis = [
    ("48", "Total Incidents", "-18% vs last month", BRAND_TEAL),
    ("96.4%", "Resolution Rate", "+4.2% improvement", GREEN_OK),
    ("11m", "Avg Time to Review", "Within 15m SLA target", BRAND_CYAN),
    ("34m", "Avg Time to Resolve", "Fastest: Downtown", AMBER_HIGH)
]
card_w = (sx2 - sx1 - 56) // 2
card_h = 148
for i, (val, title, sub, col) in enumerate(kpis):
    row = i // 2
    col_idx = i % 2
    kx = sx1 + 20 + col_idx * (card_w + 16)
    ky = cy + row * (card_h + 16)
    d4.rounded_rectangle([kx, ky, kx + card_w, ky + card_h], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
    d4.text((kx + 22, ky + 18), val, fill=col, font=f_h1)
    d4.text((kx + 22, ky + 68), title, fill=TEXT_DARK, font=f_small)
    d4.text((kx + 22, ky + 98), sub, fill=TEXT_MUTED, font=f_tiny)

# Daily Severity Trend Bar Chart Card
cy += 335
d4.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 340], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d4.text((sx1 + 40, cy + 20), "DAILY INCIDENT TREND (BY SEVERITY)", fill=TEXT_MUTED, font=f_tiny)

days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
bars = [(90, 35), (65, 20), (115, 45), (75, 25), (130, 50), (95, 30), (50, 15)]
bx = sx1 + 52
base_y = cy + 275
for d_lbl, (h_tot, h_crit) in zip(days, bars):
    d4.rounded_rectangle([bx, base_y - h_tot, bx + 44, base_y], radius=8, fill=BRAND_TEAL)
    d4.rounded_rectangle([bx, base_y - h_crit, bx + 44, base_y], radius=8, fill=BRAND_GOLD)
    draw_centered_text(d4, base_y + 12, d_lbl, f_tiny, TEXT_SLATE, center_x=bx + 22)
    bx += 80

# Branch Leaderboard Table Card
cy += 360
d4.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 445], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d4.text((sx1 + 40, cy + 20), "BRANCH RESOLUTION LEADERBOARD", fill=TEXT_MUTED, font=f_tiny)

branches = [
    ("1. Downtown Flagship", "18 incidents  •  Avg 9m response", "98% Resolved", GREEN_OK, GREEN_BG),
    ("2. Gulberg Main", "14 incidents  •  Avg 12m response", "95% Resolved", GREEN_OK, GREEN_BG),
    ("3. DHA Phase 5", "11 incidents  •  Avg 14m response", "91% Resolved", BRAND_TEAL, (224, 242, 241)),
    ("4. Mall Road Express", "5 incidents   •  Avg 19m response", "86% Resolved", AMBER_HIGH, AMBER_BG)
]
by = cy + 62
for b_name, b_sub, b_rate, fg, bg in branches:
    d4.text((sx1 + 40, by), b_name, fill=TEXT_DARK, font=f_bold)
    d4.text((sx1 + 40, by + 28), b_sub, fill=TEXT_SLATE, font=f_tiny)
    d4.rounded_rectangle([sx2 - 175, by + 4, sx2 - 40, by + 42], radius=10, fill=bg)
    draw_centered_text(d4, by + 14, b_rate, f_tiny, fg, center_x=sx2 - 107)
    if by < cy + 320:
        d4.line([(sx1 + 40, by + 68), (sx2 - 40, by + 68)], fill=(241, 245, 249), width=1)
    by += 90

img4.save('play_store_assets/screenshot_4_analytics.png', 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 5: Enterprise Security & Bilingual Support
# ==============================================================================
img5, d5, sx1, sy1, sx2, sy2 = create_phone_canvas(
    "ENTERPRISE-GRADE SECURITY",
    "Biometric app lock, customer privacy shield & Urdu RTL support",
    active_nav=2
)

d5.text((sx1 + 26, sy1 + 58), "Partner Profile & Security", fill=TEXT_WHITE, font=f_appbar)

cy = sy1 + 150
# Partner Profile Header Card
d5.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 165], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.ellipse([sx1 + 42, cy + 32, sx1 + 122, cy + 112], fill=BRAND_TEAL)
draw_centered_text(d5, cy + 54, "AR", f_appbar, BRAND_GOLD, center_x=sx1 + 82)
d5.text((sx1 + 145, cy + 34), "Arsalan Peerzada", fill=TEXT_DARK, font=f_h2)
d5.text((sx1 + 145, cy + 68), "Business Owner  •  Reweu Hospitality Group", fill=TEXT_SLATE, font=f_small)
d5.rounded_rectangle([sx1 + 145, cy + 102, sx1 + 355, cy + 134], radius=8, fill=GREEN_BG)
d5.text((sx1 + 160, cy + 109), "Verified Partner Account", fill=GREEN_OK, font=f_tiny)

# Security & Privacy Settings Card
cy += 185
d5.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 540], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.text((sx1 + 40, cy + 22), "SECURITY & PRIVACY CONTROLS", fill=TEXT_MUTED, font=f_tiny)

settings = [
    ("Biometric Unlock (Face ID / Fingerprint)", "Locks automatically after 60s in background", True),
    ("Customer Screen Privacy (FLAG_SECURE)", "Blocks screenshots & recording on incident details", True),
    ("Critical Incident Push Alerts", "High-priority sound alert for 1★ & 2★ reviews", True),
    ("Encrypted Offline Mode", "AES-encrypted local cache when offline", True)
]
sy = cy + 65
for title, sub, enabled in settings:
    d5.text((sx1 + 40, sy), title, fill=TEXT_DARK, font=f_bold)
    d5.text((sx1 + 40, sy + 28), sub, fill=TEXT_SLATE, font=f_tiny)
    # Toggle switch
    d5.rounded_rectangle([sx2 - 102, sy + 8, sx2 - 42, sy + 40], radius=16, fill=GREEN_OK)
    d5.ellipse([sx2 - 70, sy + 12, sx2 - 46, sy + 36], fill=TEXT_WHITE)
    d5.line([(sx1 + 40, sy + 76), (sx2 - 40, sy + 76)], fill=(241, 245, 249), width=1)
    sy += 112

# Language & Localization Card
cy += 560
d5.rounded_rectangle([sx1 + 20, cy, sx2 - 20, cy + 220], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.text((sx1 + 40, cy + 22), "LANGUAGE & LOCALIZATION", fill=TEXT_MUTED, font=f_tiny)
d5.text((sx1 + 40, cy + 54), "Switch instantly between English and Urdu (RTL)", fill=TEXT_SLATE, font=f_small)

d5.rounded_rectangle([sx1 + 40, cy + 100, sx1 + 305, cy + 175], radius=14, fill=(224, 242, 241), outline=BRAND_TEAL, width=2)
draw_centered_text(d5, cy + 125, "English (Active)", f_bold, BRAND_TEAL, center_x=sx1 + 172)

d5.rounded_rectangle([sx1 + 325, cy + 100, sx2 - 40, cy + 175], radius=14, fill=SCREEN_BG, outline=BORDER_LIGHT, width=1)
draw_centered_text(d5, cy + 125, "Urdu (Nastaliq RTL)", f_bold, TEXT_SLATE, center_x=sx1 + 465)

img5.save('play_store_assets/screenshot_5_security.png', 'PNG', optimize=True)

print("All 5 unstretched, native 1080x1920 phone screenshots generated!")
