import os
from PIL import Image, ImageDraw, ImageFont

OUT_67 = 'play_store_assets/app_store/iphone_6_7_inch_1290x2796'
OUT_65 = 'play_store_assets/app_store/iphone_6_5_inch_1242x2688'
os.makedirs(OUT_67, exist_ok=True)
os.makedirs(OUT_65, exist_ok=True)

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

logo_raw = Image.open('assets/images/logo.png').convert('RGBA')
logo_crop = logo_raw.crop(logo_raw.getbbox()) # (700, 218)

# 1. Generate 1024x1024 App Store Icon (Strictly RGB, NO alpha channel as required by Apple)
icon_1024 = Image.new('RGB', (1024, 1024), BRAND_TEAL)
tw = 820
th = int(logo_crop.size[1] * (tw / logo_crop.size[0]))
logo_resized = logo_crop.resize((tw, th), Image.Resampling.LANCZOS)
icon_1024.paste(logo_resized, ((1024 - tw) // 2, (1024 - th) // 2), logo_resized)
icon_1024.save('play_store_assets/app_store/app_icon_1024_ios.png', 'PNG', optimize=True)

# Fonts scaled natively for 1290x2796 iPhone 6.7" Super Retina XDR
f_headline = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 62)
f_subtitle = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 30)
f_appbar = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 36)
f_h1 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 48)
f_h2 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 30)
f_bold = ImageFont.truetype('assets/fonts/PlusJakartaSans-Bold.ttf', 25)
f_semi = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 23)
f_body = ImageFont.truetype('assets/fonts/PlusJakartaSans-Regular.ttf', 22)
f_small = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 20)
f_tiny = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 18)


def draw_centered_text(draw, y, text, font, fill, center_x=645):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((center_x - tw // 2, y), text, fill=fill, font=font)


def create_iphone_canvas(headline, subtitle, active_nav=0, show_bottom_nav=True):
    """Creates a native 1290x2796 (iPhone 6.7" Pro Max) canvas with an authentic iPhone Dynamic Island chassis."""
    W, H = 1290, 2796
    img = Image.new('RGB', (W, H), BG_TOP)
    draw = ImageDraw.Draw(img)

    # Vertical background gradient
    for y in range(H):
        ratio = y / H
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * ratio)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * ratio)
        draw.line([(0, y), (W, y)], fill=(0, g, b))

    # Top Reweu Partners Logo
    lw = 300
    lh = int(logo_crop.size[1] * (lw / logo_crop.size[0]))
    logo_sm = logo_crop.resize((lw, lh), Image.Resampling.LANCZOS)
    img.paste(logo_sm, ((W - lw) // 2, 85), logo_sm)

    # Headline & Subtitle
    draw_centered_text(draw, 215, headline, f_headline, TEXT_WHITE, center_x=W // 2)
    draw_centered_text(draw, 300, subtitle, f_subtitle, (203, 213, 225), center_x=W // 2)

    # Slender iPhone 16 Pro Max Frame (920 x 2260 -> ~9:19.5 aspect ratio, 185px side margins)
    px1, py1 = 185, 410
    px2, py2 = 1105, 2670

    # iPhone Titanium Side Buttons (Action button + Volume buttons on left, Power button on right)
    draw.rounded_rectangle([px1 - 8, py1 + 260, px1 + 2, py1 + 315], radius=3, fill=(71, 85, 105))
    draw.rounded_rectangle([px1 - 8, py1 + 360, px1 + 2, py1 + 465], radius=3, fill=(71, 85, 105))
    draw.rounded_rectangle([px1 - 8, py1 + 495, px1 + 2, py1 + 600], radius=3, fill=(71, 85, 105))
    draw.rounded_rectangle([px2 - 2, py1 + 410, px2 + 8, py1 + 575], radius=3, fill=(71, 85, 105))

    # Titanium outer rim + ultra-thin bezel
    draw.rounded_rectangle([px1 - 5, py1 - 5, px2 + 5, py2 + 5], radius=105, fill=(71, 85, 105), outline=(148, 163, 184), width=2)
    draw.rounded_rectangle([px1, py1, px2, py2], radius=100, fill=(15, 23, 42))

    # Inner iPhone OLED Display
    sx1, sy1 = px1 + 20, py1 + 20
    sx2, sy2 = px2 - 20, py2 - 20
    draw.rounded_rectangle([sx1, sy1, sx2, sy2], radius=82, fill=SCREEN_BG)

    # Top Header Bar inside iPhone screen
    draw.rounded_rectangle([sx1, sy1, sx2, sy1 + 195], radius=82, fill=BRAND_TEAL)
    draw.rectangle([sx1, sy1 + 85, sx2, sy1 + 195], fill=BRAND_TEAL)

    # Authentic iPhone Dynamic Island (pill-shaped cutout at top center)
    di_w, di_h = 190, 44
    di_x = (W - di_w) // 2
    di_y = sy1 + 20
    draw.rounded_rectangle([di_x, di_y, di_x + di_w, di_y + di_h], radius=22, fill=(8, 12, 20))
    # Subtle lens reflection inside Dynamic Island
    draw.ellipse([di_x + di_w - 36, di_y + 12, di_x + di_w - 16, di_y + 32], fill=(22, 32, 52))

    # iOS Status Bar Time & 5G/Battery
    draw.text((sx1 + 52, sy1 + 28), "9:41", fill=TEXT_WHITE, font=f_small)
    draw.text((sx2 - 145, sy1 + 28), "5G   100%", fill=TEXT_WHITE, font=f_tiny)

    # Bottom iOS Tab Bar + Home Indicator
    if show_bottom_nav:
        nav_y = sy2 - 130
        draw.rounded_rectangle([sx1, nav_y, sx2, sy2], radius=82, fill=CARD_WHITE)
        draw.rectangle([sx1, nav_y, sx2, nav_y + 60], fill=CARD_WHITE)
        draw.line([(sx1, nav_y), (sx2, nav_y)], fill=BORDER_LIGHT, width=2)

        nav_items = ["Incidents", "Analytics", "Profile"]
        col_w = (sx2 - sx1) // 3
        for idx, label in enumerate(nav_items):
            cx = sx1 + idx * col_w + col_w // 2
            is_act = (idx == active_nav)
            pill_col = (224, 242, 241) if is_act else CARD_WHITE
            txt_col = BRAND_TEAL if is_act else TEXT_MUTED
            if is_act:
                draw.rounded_rectangle([cx - 72, nav_y + 16, cx + 72, nav_y + 56], radius=20, fill=pill_col)
            draw_centered_text(draw, nav_y + 24, label, f_small if is_act else f_tiny, txt_col, center_x=cx)

    # iOS Home Indicator Bar
    draw.rounded_rectangle([W // 2 - 115, sy2 - 22, W // 2 + 115, sy2 - 14], radius=4, fill=(148, 163, 184))

    return img, draw, sx1, sy1, sx2, sy2


def save_both_ios_sizes(img_67, filename):
    """Saves native 1290x2796 (6.7") and proportional 1242x2688 (6.5" — identical 9:19.5 aspect ratio!)."""
    p67 = os.path.join(OUT_67, filename)
    img_67.save(p67, 'PNG', optimize=True)
    # Note: 1290/2796 = 0.46137 and 1242/2688 = 0.46205 (99.85% identical aspect ratio, zero distortion!)
    img_65 = img_67.resize((1242, 2688), Image.Resampling.LANCZOS)
    p65 = os.path.join(OUT_65, filename)
    img_65.save(p65, 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 1: Real-Time Incident Feed
# ==============================================================================
img1, d1, sx1, sy1, sx2, sy2 = create_iphone_canvas(
    "REAL-TIME INCIDENT FEED",
    "Catch low-scoring customer reviews the moment they happen",
    active_nav=0
)

d1.text((sx1 + 36, sy1 + 102), "Reweu Partners", fill=TEXT_WHITE, font=f_appbar)
d1.rounded_rectangle([sx2 - 245, sy1 + 98, sx2 - 32, sy1 + 152], radius=16, fill=(0, 76, 89), outline=(0, 120, 138), width=1)
d1.text((sx2 - 222, sy1 + 113), "All Branches  v", fill=TEXT_WHITE, font=f_tiny)

# Search Bar
cy = sy1 + 220
d1.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 68], radius=18, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d1.text((sx1 + 54, cy + 21), "Search customer, order # or branch...", fill=TEXT_MUTED, font=f_tiny)

# Filter Chips
cy += 90
chips = [("All (12)", True), ("Critical (3)", False), ("Open (5)", False), ("Resolved (4)", False)]
cx = sx1 + 28
for label, active in chips:
    bbox = d1.textbbox((0, 0), label, font=f_tiny)
    cw = (bbox[2] - bbox[0]) + 44
    bg = BRAND_TEAL if active else CARD_WHITE
    fg = TEXT_WHITE if active else TEXT_SLATE
    d1.rounded_rectangle([cx, cy, cx + cw, cy + 52], radius=26, fill=bg, outline=BRAND_TEAL if active else BORDER_LIGHT, width=1)
    d1.text((cx + 22, cy + 14), label, fill=fg, font=f_tiny)
    cx += cw + 14

# 4 Incident Cards
cards = [
    {
        "id": "#INC-1082", "branch": "Downtown Branch", "time": "2m ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Farhan Ahmed", "rating": "1.0 ★  Food Quality",
        "l1": "\"Ordered the family platter, food arrived cold and",
        "l2": "specialty dipping sauces were missing.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    },
    {
        "id": "#INC-1081", "branch": "Gulberg Flagship", "time": "14m ago",
        "sev": "HIGH", "sev_fg": AMBER_HIGH, "sev_bg": AMBER_BG,
        "cust": "Sara Malik", "rating": "2.0 ★  Slow Service",
        "l1": "\"Waited 40 minutes for table service during lunch",
        "l2": "hour. Staff seemed overwhelmed.\"",
        "status": "In Review", "btn_bg": (224, 242, 241), "btn_fg": BRAND_TEAL
    },
    {
        "id": "#INC-1079", "branch": "DHA Phase 5", "time": "48m ago",
        "sev": "RESOLVED", "sev_fg": GREEN_OK, "sev_bg": GREEN_BG,
        "cust": "Usman Tariq", "rating": "1.0 ★  Recovered (PKR 1,500 Voucher)",
        "l1": "\"Manager called within 5 minutes, apologized and",
        "l2": "issued a recovery voucher for our next visit.\"",
        "status": "Resolved", "btn_bg": GREEN_BG, "btn_fg": GREEN_OK
    },
    {
        "id": "#INC-1076", "branch": "Mall Road Outlet", "time": "2h ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Ayesha Siddiqui", "rating": "1.0 ★  Wrong Order Item",
        "l1": "\"Received spicy chicken instead of mild kids meal.",
        "l2": "Needs immediate replacement.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    }
]

cy += 78
for c in cards:
    ch = 350
    d1.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + ch], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
    d1.rounded_rectangle([sx1 + 28, cy + 22, sx1 + 36, cy + ch - 22], radius=4, fill=c["sev_fg"])

    d1.text((sx1 + 58, cy + 24), f"{c['id']}  •  {c['branch']}", fill=TEXT_SLATE, font=f_tiny)
    d1.rounded_rectangle([sx2 - 185, cy + 20, sx2 - 50, cy + 56], radius=10, fill=c["sev_bg"])
    draw_centered_text(d1, cy + 27, c["sev"], f_tiny, c["sev_fg"], center_x=sx2 - 117)

    d1.text((sx1 + 58, cy + 66), c["cust"], fill=TEXT_DARK, font=f_bold)
    d1.text((sx2 - 130, cy + 70), c["time"], fill=TEXT_MUTED, font=f_tiny)

    d1.text((sx1 + 58, cy + 108), c["rating"], fill=c["sev_fg"], font=f_small)

    d1.text((sx1 + 58, cy + 150), c["l1"], fill=TEXT_SLATE, font=f_body)
    d1.text((sx1 + 58, cy + 184), c["l2"], fill=TEXT_SLATE, font=f_body)

    d1.line([(sx1 + 58, cy + 245), (sx2 - 50, cy + 245)], fill=(241, 245, 249), width=2)
    d1.text((sx1 + 58, cy + 275), "Tap to view timeline & contact", fill=TEXT_MUTED, font=f_tiny)
    d1.rounded_rectangle([sx2 - 225, cy + 262, sx2 - 50, cy + 324], radius=16, fill=c["btn_bg"])
    draw_centered_text(d1, cy + 280, c["status"], f_small, c["btn_fg"], center_x=sx2 - 137)

    cy += ch + 24

save_both_ios_sizes(img1, 'ios_screenshot_1_feed.png')


# ==============================================================================
# SCREENSHOT 2: Rapid Customer Triage & Contact
# ==============================================================================
img2, d2, sx1, sy1, sx2, sy2 = create_iphone_canvas(
    "INSTANT CUSTOMER TRIAGE",
    "Call, WhatsApp, or email dissatisfied guests in one tap",
    active_nav=0
)

d2.text((sx1 + 36, sy1 + 102), "←  Incident #INC-1082", fill=TEXT_WHITE, font=f_appbar)
d2.rounded_rectangle([sx2 - 175, sy1 + 100, sx2 - 34, sy1 + 148], radius=12, fill=RED_CRIT)
draw_centered_text(d2, sy1 + 112, "CRITICAL", f_tiny, TEXT_WHITE, center_x=sx2 - 104)

cy = sy1 + 220
# Card 1: Customer Contact
d2.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 380], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 54, cy + 28), "CUSTOMER DETAILS", fill=TEXT_MUTED, font=f_tiny)
d2.text((sx1 + 54, cy + 66), "Farhan Ahmed", fill=TEXT_DARK, font=f_h2)
d2.text((sx1 + 54, cy + 114), "+92 300 8492011  •  farhan.a@gmail.com", fill=TEXT_SLATE, font=f_body)
d2.text((sx1 + 54, cy + 156), "Branch: Downtown Branch  •  Table / Order #4892", fill=BRAND_CYAN, font=f_small)

btns = [
    ("Call Guest", (37, 99, 235)),
    ("WhatsApp", (22, 163, 74)),
    ("Send Email", (71, 85, 105))
]
bw = 238
bx = sx1 + 54
for label, col in btns:
    d2.rounded_rectangle([bx, cy + 216, bx + bw, cy + 294], radius=18, fill=col)
    draw_centered_text(d2, cy + 242, label, f_small, TEXT_WHITE, center_x=bx + bw // 2)
    bx += bw + 28

d2.text((sx1 + 54, cy + 322), "Privacy Shield: App-switcher snapshot & screen capture protected", fill=TEXT_MUTED, font=f_tiny)

# Card 2: Review Trigger
cy += 410
d2.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 435], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 54, cy + 28), "LOW-SCORE REVIEW TRIGGER", fill=TEXT_MUTED, font=f_tiny)
d2.text((sx1 + 54, cy + 68), "★ 1.0 / 5.0  —  Food Quality & Accuracy", fill=RED_CRIT, font=f_bold)
d2.rounded_rectangle([sx1 + 54, cy + 122, sx2 - 54, cy + 300], radius=18, fill=SCREEN_BG)
d2.text((sx1 + 78, cy + 146), "\"Ordered the family platter for our dinner guests.", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 78, cy + 186), "The food arrived completely cold and all specialty", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 78, cy + 226), "dipping sauces were missing from the bag.\"", fill=TEXT_DARK, font=f_body)
d2.text((sx1 + 54, cy + 328), "Staff on Duty: Bilal H. (Shift Supervisor)", fill=TEXT_SLATE, font=f_small)
d2.text((sx1 + 54, cy + 370), "SLA Timer: Respond within 15 mins (11m remaining)", fill=AMBER_HIGH, font=f_small)

# Card 3: Internal Notes & Timeline
cy += 465
d2.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 610], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 54, cy + 28), "INTERNAL NOTES & AUDIT TIMELINE", fill=TEXT_MUTED, font=f_tiny)

timeline = [
    ("10:14 AM  —  Incident raised from 1★ customer review", "Automatically assigned to Downtown Branch", TEXT_SLATE),
    ("10:16 AM  —  Acknowledged by Branch Manager", "Ali Raza took ownership of this incident", BRAND_TEAL),
    ("10:19 AM  —  Team Note Added", "Called guest, apologized & dispatched hot replacement", GREEN_OK)
]
ty = cy + 78
for line_top, line_sub, col in timeline:
    d2.ellipse([sx1 + 54, ty + 6, sx1 + 72, ty + 24], fill=col)
    d2.text((sx1 + 92, ty), line_top, fill=TEXT_DARK, font=f_small)
    d2.text((sx1 + 92, ty + 32), line_sub, fill=TEXT_SLATE, font=f_tiny)
    ty += 88

d2.rounded_rectangle([sx1 + 54, cy + 350, sx2 - 54, cy + 475], radius=16, fill=SCREEN_BG, outline=BORDER_LIGHT, width=2)
d2.text((sx1 + 76, cy + 374), "Add internal triage note for staff...", fill=TEXT_MUTED, font=f_body)
d2.text((sx2 - 175, cy + 435), "0 / 500 chars", fill=TEXT_MUTED, font=f_tiny)

d2.rounded_rectangle([sx1 + 54, cy + 502, sx2 - 54, cy + 582], radius=18, fill=BRAND_TEAL)
draw_centered_text(d2, cy + 526, "Resolve Incident & Issue Voucher", f_bold, TEXT_WHITE, center_x=645)

save_both_ios_sizes(img2, 'ios_screenshot_2_triage.png')


# ==============================================================================
# SCREENSHOT 3: Service Recovery Vouchers
# ==============================================================================
img3, d3, sx1, sy1, sx2, sy2 = create_iphone_canvas(
    "SERVICE RECOVERY VOUCHERS",
    "Turn unhappy guests into loyal regulars with instant vouchers",
    active_nav=0
)

d3.text((sx1 + 36, sy1 + 102), "Resolve Incident #INC-1082", fill=TEXT_WHITE, font=f_appbar)

cy = sy1 + 220
d3.rounded_rectangle([sx1 + 28, cy, sx2 - 28, sy2 - 155], radius=28, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)

d3.text((sx1 + 58, cy + 40), "1. Select Resolution Status", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([sx1 + 58, cy + 100, sx1 + 425, cy + 205], radius=18, fill=GREEN_BG, outline=GREEN_OK, width=2)
d3.text((sx1 + 86, cy + 122), "Resolved (Selected)", fill=GREEN_OK, font=f_bold)
d3.text((sx1 + 86, cy + 160), "Issue fixed with customer", fill=GREEN_OK, font=f_tiny)

d3.rounded_rectangle([sx1 + 455, cy + 100, sx2 - 58, cy + 205], radius=18, fill=SCREEN_BG, outline=BORDER_LIGHT, width=1)
d3.text((sx1 + 485, cy + 122), "Acknowledged", fill=TEXT_SLATE, font=f_bold)
d3.text((sx1 + 485, cy + 160), "Under investigation", fill=TEXT_MUTED, font=f_tiny)

# Voucher Section
d3.text((sx1 + 58, cy + 252), "2. Service Recovery Voucher", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([sx1 + 58, cy + 312, sx2 - 58, cy + 630], radius=24, fill=(240, 253, 250), outline=BRAND_CYAN, width=2)
d3.text((sx1 + 88, cy + 344), "Attach Goodwill Compensation Voucher", fill=BRAND_TEAL, font=f_bold)
d3.rounded_rectangle([sx2 - 170, cy + 338, sx2 - 88, cy + 382], radius=22, fill=GREEN_OK)
d3.ellipse([sx2 - 126, cy + 344, sx2 - 94, cy + 376], fill=TEXT_WHITE)

d3.text((sx1 + 88, cy + 408), "Voucher Amount (PKR)  •  Max Limit: PKR 50,000", fill=TEXT_SLATE, font=f_tiny)
d3.rounded_rectangle([sx1 + 88, cy + 448, sx2 - 88, cy + 542], radius=16, fill=CARD_WHITE, outline=BRAND_TEAL, width=2)
d3.text((sx1 + 116, cy + 472), "PKR  1,500", fill=BRAND_TEAL, font=f_appbar)
d3.text((sx2 - 250, cy + 482), "Valid for 30 days", fill=GREEN_OK, font=f_tiny)
d3.text((sx1 + 88, cy + 568), "Voucher code is sent automatically to customer upon resolution", fill=BRAND_TEAL, font=f_tiny)

# Top-aligned Resolution Summary
d3.text((sx1 + 58, cy + 680), "3. Resolution Summary (Required)", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([sx1 + 58, cy + 740, sx2 - 58, cy + 1120], radius=22, fill=SCREEN_BG, outline=BORDER_LIGHT, width=2)
summary_lines = [
    "Spoke with Mr. Farhan directly on phone and apologized",
    "for the cold platter and missing sauces.",
    "",
    "Dispatched a fresh hot replacement order via express",
    "rider and issued a PKR 1,500 recovery voucher for his",
    "next family visit. Customer was very appreciative."
]
sy_text = cy + 772
for line in summary_lines:
    d3.text((sx1 + 86, sy_text), line, fill=TEXT_DARK, font=f_body)
    sy_text += 40

d3.text((sx2 - 215, cy + 1072), "242 / 500 chars", fill=TEXT_MUTED, font=f_tiny)

# Confirm CTA
d3.rounded_rectangle([sx1 + 58, cy + 1175, sx2 - 58, cy + 1270], radius=22, fill=BRAND_TEAL)
draw_centered_text(d3, cy + 1205, "Confirm Resolution & Send Voucher", f_bold, TEXT_WHITE, center_x=645)

save_both_ios_sizes(img3, 'ios_screenshot_3_recovery.png')


# ==============================================================================
# SCREENSHOT 4: Multi-Branch & Staff Analytics
# ==============================================================================
img4, d4, sx1, sy1, sx2, sy2 = create_iphone_canvas(
    "BRANCH & STAFF ANALYTICS",
    "Track resolution speed, incident trends, and location performance",
    active_nav=1
)

d4.text((sx1 + 36, sy1 + 102), "Performance Analytics", fill=TEXT_WHITE, font=f_appbar)
periods = [("7 Days", False), ("30 Days", True), ("90 Days", False)]
px = sx2 - 315
for p_lbl, act in periods:
    d4.rounded_rectangle([px, sy1 + 104, px + 92, sy1 + 146], radius=12, fill=BRAND_GOLD if act else (0, 76, 89))
    draw_centered_text(d4, sy1 + 114, p_lbl, f_tiny, TEXT_DARK if act else TEXT_WHITE, center_x=px + 46)
    px += 100

cy = sy1 + 220
kpis = [
    ("48", "Total Incidents", "-18% vs last month", BRAND_TEAL),
    ("96.4%", "Resolution Rate", "+4.2% improvement", GREEN_OK),
    ("11m", "Avg Time to Review", "Within 15m SLA target", BRAND_CYAN),
    ("34m", "Avg Time to Resolve", "Fastest: Downtown", AMBER_HIGH)
]
card_w = (sx2 - sx1 - 78) // 2
card_h = 210
for i, (val, title, sub, col) in enumerate(kpis):
    row = i // 2
    col_idx = i % 2
    kx = sx1 + 28 + col_idx * (card_w + 22)
    ky = cy + row * (card_h + 22)
    d4.rounded_rectangle([kx, ky, kx + card_w, ky + card_h], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
    d4.text((kx + 30, ky + 26), val, fill=col, font=f_h1)
    d4.text((kx + 30, ky + 98), title, fill=TEXT_DARK, font=f_small)
    d4.text((kx + 30, ky + 140), sub, fill=TEXT_MUTED, font=f_tiny)

# Daily Severity Trend Bar Chart
cy += 475
d4.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 480], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d4.text((sx1 + 54, cy + 28), "DAILY INCIDENT TREND (BY SEVERITY)", fill=TEXT_MUTED, font=f_tiny)

days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
bars = [(130, 50), (95, 30), (165, 65), (110, 35), (185, 70), (135, 42), (72, 22)]
bx = sx1 + 72
base_y = cy + 390
for d_lbl, (h_tot, h_crit) in zip(days, bars):
    d4.rounded_rectangle([bx, base_y - h_tot, bx + 60, base_y], radius=10, fill=BRAND_TEAL)
    d4.rounded_rectangle([bx, base_y - h_crit, bx + 60, base_y], radius=10, fill=BRAND_GOLD)
    draw_centered_text(d4, base_y + 18, d_lbl, f_tiny, TEXT_SLATE, center_x=bx + 30)
    bx += 110

# Branch Leaderboard
cy += 510
d4.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 630], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d4.text((sx1 + 54, cy + 28), "BRANCH RESOLUTION LEADERBOARD", fill=TEXT_MUTED, font=f_tiny)

branches = [
    ("1. Downtown Flagship", "18 incidents  •  Avg 9m response", "98% Resolved", GREEN_OK, GREEN_BG),
    ("2. Gulberg Main", "14 incidents  •  Avg 12m response", "95% Resolved", GREEN_OK, GREEN_BG),
    ("3. DHA Phase 5", "11 incidents  •  Avg 14m response", "91% Resolved", BRAND_TEAL, (224, 242, 241)),
    ("4. Mall Road Express", "5 incidents   •  Avg 19m response", "86% Resolved", AMBER_HIGH, AMBER_BG)
]
by = cy + 88
for b_name, b_sub, b_rate, fg, bg in branches:
    d4.text((sx1 + 54, by), b_name, fill=TEXT_DARK, font=f_bold)
    d4.text((sx1 + 54, by + 40), b_sub, fill=TEXT_SLATE, font=f_tiny)
    d4.rounded_rectangle([sx2 - 235, by + 6, sx2 - 54, by + 58], radius=14, fill=bg)
    draw_centered_text(d4, by + 20, b_rate, f_tiny, fg, center_x=sx2 - 144)
    if by < cy + 450:
        d4.line([(sx1 + 54, by + 96), (sx2 - 54, by + 96)], fill=(241, 245, 249), width=2)
    by += 128

save_both_ios_sizes(img4, 'ios_screenshot_4_analytics.png')


# ==============================================================================
# SCREENSHOT 5: Enterprise Security & Bilingual Support
# ==============================================================================
img5, d5, sx1, sy1, sx2, sy2 = create_iphone_canvas(
    "FACE ID & PRIVACY PROTECTION",
    "Biometric app lock, privacy overlay & bilingual Urdu RTL support",
    active_nav=2
)

d5.text((sx1 + 36, sy1 + 102), "Partner Profile & Security", fill=TEXT_WHITE, font=f_appbar)

cy = sy1 + 220
d5.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 235], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.ellipse([sx1 + 58, cy + 46, sx1 + 170, cy + 158], fill=BRAND_TEAL)
draw_centered_text(d5, cy + 78, "AP", f_appbar, BRAND_GOLD, center_x=sx1 + 114)
d5.text((sx1 + 200, cy + 48), "Arsalan Peerzada", fill=TEXT_DARK, font=f_h2)
d5.text((sx1 + 200, cy + 96), "Business Owner  •  Reweu Hospitality Group", fill=TEXT_SLATE, font=f_small)
d5.rounded_rectangle([sx1 + 200, cy + 144, sx1 + 485, cy + 190], radius=10, fill=GREEN_BG)
d5.text((sx1 + 220, cy + 155), "Verified Partner Account", fill=GREEN_OK, font=f_tiny)

cy += 265
d5.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 760], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.text((sx1 + 54, cy + 30), "IOS SECURITY & PRIVACY CONTROLS", fill=TEXT_MUTED, font=f_tiny)

settings = [
    ("Face ID / Touch ID App Lock", "Locks automatically after 60s in background", True),
    ("App-Switcher Privacy Shield", "Hides customer details in iOS multitasking view", True),
    ("Critical Incident Push Alerts (APNs)", "Time-sensitive alert sound for 1★ & 2★ reviews", True),
    ("Keychain-Backed Offline Cache", "Encrypted local storage when network drops", True)
]
sy = cy + 92
for title, sub, enabled in settings:
    d5.text((sx1 + 54, sy), title, fill=TEXT_DARK, font=f_bold)
    d5.text((sx1 + 54, sy + 40), sub, fill=TEXT_SLATE, font=f_tiny)
    d5.rounded_rectangle([sx2 - 140, sy + 10, sx2 - 54, sy + 56], radius=23, fill=GREEN_OK)
    d5.ellipse([sx2 - 96, sy + 15, sx2 - 60, sy + 51], fill=TEXT_WHITE)
    d5.line([(sx1 + 54, sy + 108), (sx2 - 54, sy + 108)], fill=(241, 245, 249), width=2)
    sy += 158

cy += 790
d5.rounded_rectangle([sx1 + 28, cy, sx2 - 28, cy + 315], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=2)
d5.text((sx1 + 54, cy + 30), "LANGUAGE & LOCALIZATION", fill=TEXT_MUTED, font=f_tiny)
d5.text((sx1 + 54, cy + 76), "Switch instantly between English and Urdu (RTL)", fill=TEXT_SLATE, font=f_small)

d5.rounded_rectangle([sx1 + 54, cy + 140, sx1 + 420, cy + 250], radius=18, fill=(224, 242, 241), outline=BRAND_TEAL, width=2)
draw_centered_text(d5, cy + 178, "English (Active)", f_bold, BRAND_TEAL, center_x=sx1 + 237)

d5.rounded_rectangle([sx1 + 448, cy + 140, sx2 - 54, cy + 250], radius=18, fill=SCREEN_BG, outline=BORDER_LIGHT, width=1)
draw_centered_text(d5, cy + 178, "Urdu (Nastaliq RTL)", f_bold, TEXT_SLATE, center_x=sx1 + 642)

save_both_ios_sizes(img5, 'ios_screenshot_5_security.png')

print("All Apple App Store assets generated successfully!")
