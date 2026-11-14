import math
import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = 'play_store_assets/app_store'
OUT_61 = os.path.join(OUT_DIR, 'iphone_6_1_inch_1179x2556')
OUT_63 = os.path.join(OUT_DIR, 'iphone_6_3_inch_1206x2622')
OUT_67 = os.path.join(OUT_DIR, 'iphone_6_7_inch_1290x2796')
os.makedirs(OUT_61, exist_ok=True)
os.makedirs(OUT_63, exist_ok=True)
os.makedirs(OUT_67, exist_ok=True)

# Brand & iOS Native UI Palette
BRAND_TEAL = (0, 52, 61)       # #00343D
BRAND_DARK = (0, 36, 43)       # #00242B
BRAND_GOLD = (255, 165, 2)     # #FFA502
BRAND_CYAN = (0, 168, 181)     # #00A8B5
SCREEN_BG = (242, 244, 248)    # #F2F4F8 iOS grouped background
CARD_WHITE = (255, 255, 255)
BORDER_LIGHT = (226, 232, 240)
DIVIDER = (238, 242, 246)
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

# Fonts for 1290x2796 (3x Retina scale, matching real iPhone 15/16 Pro Max point sizes * 3)
f_status = ImageFont.truetype('assets/fonts/PlusJakartaSans-Bold.ttf', 44)      # ~15pt @3x
f_nav_title = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 58)            # ~19pt @3x
f_h1 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 74)                   # ~25pt @3x
f_h2 = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', 46)                   # ~16pt @3x
f_bold = ImageFont.truetype('assets/fonts/PlusJakartaSans-Bold.ttf', 38)        # ~13pt @3x
f_semi = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 35)    # ~12pt @3x
f_body = ImageFont.truetype('assets/fonts/PlusJakartaSans-Regular.ttf', 34)     # ~11.5pt @3x
f_small = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 30)   # ~10pt @3x
f_tiny = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', 27)      # ~9pt @3x
f_tab = ImageFont.truetype('assets/fonts/PlusJakartaSans-SemiBold.ttf', 28)


def draw_centered_text(draw, y, text, font, fill, center_x=645):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((center_x - tw // 2, y), text, fill=fill, font=font)


def draw_ios_status_bar(img, color=(255, 255, 255)):
    """
    Draws an authentic iOS Status Bar at 4x supersampling for crisp anti-aliased icons:
    - Left: '9:41' in semi-bold
    - Right: 4 ascending Apple cellular bars, 3-arc Apple Wi-Fi icon, and Apple Battery icon with cap
    """
    draw = ImageDraw.Draw(img)
    # Time on left (aligned with iOS safe area)
    draw.text((108, 54), "9:41", fill=color, font=f_status)

    # Render right-side status icons at 4x supersampling for razor-sharp curves
    scale = 4
    iw, ih = 320 * scale, 60 * scale
    icon_layer = Image.new('RGBA', (iw, ih), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(icon_layer)

    # 1. Cellular Signal Bars (4 ascending rounded bars)
    # Positioned at x = 20..95 (in 1x coords)
    bar_heights = [14, 21, 29, 37]
    bar_w = 9
    bar_gap = 6
    base_y = 45
    for idx, bh in enumerate(bar_heights):
        bx1 = (20 + idx * (bar_w + bar_gap)) * scale
        by1 = (base_y - bh) * scale
        bx2 = (20 + idx * (bar_w + bar_gap) + bar_w) * scale
        by2 = base_y * scale
        idraw.rounded_rectangle([bx1, by1, bx2, by2], radius=3 * scale, fill=color + (255,))

    # 2. Apple Wi-Fi Icon (3 concentric arcs + bottom circle dot)
    # Center at x = 132, bottom dot at y = 41
    wx, wy = 132 * scale, 42 * scale
    dot_r = 4 * scale
    idraw.ellipse([wx - dot_r, wy - dot_r, wx + dot_r, wy + dot_r], fill=color + (255,))
    for radius, thickness in [(14 * scale, 4.5 * scale), (25 * scale, 4.5 * scale), (36 * scale, 4.5 * scale)]:
        bbox = [wx - radius, wy - radius, wx + radius, wy + radius]
        idraw.arc(bbox, start=222, end=318, fill=color + (255,), width=int(thickness))

    # 3. Apple Battery Icon (rounded outline + solid inner charge + right terminal nib)
    # Positioned at x = 178..252, y = 11..45
    bx1, by1 = 176 * scale, 11 * scale
    bx2, by2 = 248 * scale, 45 * scale
    # Outer battery body (slightly translucent border like real iOS)
    idraw.rounded_rectangle(
        [bx1, by1, bx2, by2],
        radius=10 * scale,
        outline=color + (165,),
        width=int(2.8 * scale)
    )
    # Inner solid battery fill (95% full)
    pad = int(5.5 * scale)
    idraw.rounded_rectangle(
        [bx1 + pad, by1 + pad, bx2 - pad - 2 * scale, by2 - pad],
        radius=6 * scale,
        fill=color + (255,)
    )
    # Right positive terminal nub
    nub_x1 = bx2 + int(2.5 * scale)
    nub_y1 = by1 + int(11 * scale)
    nub_x2 = nub_x1 + int(4.5 * scale)
    nub_y2 = by2 - int(11 * scale)
    idraw.rounded_rectangle([nub_x1, nub_y1, nub_x2, nub_y2], radius=2 * scale, fill=color + (165,))

    icon_small = icon_layer.resize((320, 60), Image.Resampling.LANCZOS)
    img.paste(icon_small, (1290 - 345, 50), icon_small)


def draw_tab_bar_icon(img, cx, cy, kind, color):
    """Draws crisp vector icons for the iOS bottom tab bar (bell, chart, person)."""
    scale = 4
    w, h = 64 * scale, 64 * scale
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = color + (255,)

    if kind == "incidents":
        # Bell / Alert icon
        d.arc([14 * scale, 8 * scale, 50 * scale, 44 * scale], start=180, end=360, fill=c, width=5 * scale)
        d.line([(14 * scale, 26 * scale), (10 * scale, 44 * scale)], fill=c, width=5 * scale)
        d.line([(50 * scale, 26 * scale), (54 * scale, 44 * scale)], fill=c, width=5 * scale)
        d.line([(8 * scale, 44 * scale), (56 * scale, 44 * scale)], fill=c, width=5 * scale)
        d.arc([25 * scale, 42 * scale, 39 * scale, 56 * scale], start=0, end=180, fill=c, width=5 * scale)
    elif kind == "analytics":
        # 3 ascending chart bars
        d.rounded_rectangle([10 * scale, 32 * scale, 21 * scale, 54 * scale], radius=3 * scale, fill=c)
        d.rounded_rectangle([26 * scale, 18 * scale, 37 * scale, 54 * scale], radius=3 * scale, fill=c)
        d.rounded_rectangle([42 * scale, 8 * scale, 53 * scale, 54 * scale], radius=3 * scale, fill=c)
    elif kind == "profile":
        # Person silhouette
        d.ellipse([20 * scale, 8 * scale, 44 * scale, 32 * scale], outline=c, width=5 * scale)
        d.arc([10 * scale, 34 * scale, 54 * scale, 68 * scale], start=190, end=350, fill=c, width=5 * scale)

    small = layer.resize((64, 64), Image.Resampling.LANCZOS)
    img.paste(small, (cx - 32, cy), small)


def create_raw_iphone_screen(title, right_pill=None, right_pill_bg=None, active_nav=0, back_btn=False):
    """
    Creates a full-bleed 1290x2796 raw iPhone screenshot (looks identically like pressing
    Side Button + Volume Up on an iPhone 16 Pro Max).
    """
    W, H = 1290, 2796
    img = Image.new('RGB', (W, H), SCREEN_BG)
    draw = ImageDraw.Draw(img)

    # Top Navigation + Status Bar Area (y = 0..275)
    draw.rectangle([0, 0, W, 275], fill=BRAND_TEAL)

    # Draw authentic Apple iOS status bar (9:41 + Cellular + Wi-Fi + Battery)
    draw_ios_status_bar(img, color=TEXT_WHITE)

    # Navigation Bar Title & Controls (y = 148..250)
    if back_btn:
        # iOS Back Chevron '<'
        draw.line([(56, 198), (78, 176)], fill=TEXT_WHITE, width=7)
        draw.line([(56, 198), (78, 220)], fill=TEXT_WHITE, width=7)
        draw.text((104, 164), title, fill=TEXT_WHITE, font=f_nav_title)
    else:
        draw.text((56, 164), title, fill=TEXT_WHITE, font=f_nav_title)

    if right_pill:
        pb = draw.textbbox((0, 0), right_pill, font=f_small)
        pw = (pb[2] - pb[0]) + 64
        p_bg = right_pill_bg if right_pill_bg else (0, 76, 89)
        draw.rounded_rectangle([W - 56 - pw, 160, W - 56, 232], radius=22, fill=p_bg, outline=(0, 120, 138) if not right_pill_bg else None, width=2)
        draw_centered_text(draw, 178, right_pill, f_small, TEXT_WHITE, center_x=W - 56 - pw // 2)

    # Bottom iOS Tab Bar (y = 2550..2796)
    nav_y = 2550
    draw.rectangle([0, nav_y, W, H], fill=CARD_WHITE)
    draw.line([(0, nav_y), (W, nav_y)], fill=BORDER_LIGHT, width=3)

    tabs = [("Incidents", "incidents"), ("Analytics", "analytics"), ("Profile", "profile")]
    col_w = W // 3
    for idx, (label, icon_kind) in enumerate(tabs):
        cx = idx * col_w + col_w // 2
        is_act = (idx == active_nav)
        col = BRAND_TEAL if is_act else TEXT_MUTED
        draw_tab_bar_icon(img, cx, nav_y + 24, icon_kind, col)
        draw_centered_text(draw, nav_y + 96, label, f_tab, col, center_x=cx)

    # Native iOS Bottom Home Indicator Pill
    draw.rounded_rectangle([W // 2 - 230, H - 38, W // 2 + 230, H - 22], radius=8, fill=(15, 23, 42))

    return img, draw


def save_both_ios_sizes(img_67, filename):
    os.makedirs(OUT_61, exist_ok=True)
    os.makedirs(OUT_63, exist_ok=True)
    os.makedirs(OUT_67, exist_ok=True)
    img_61 = img_67.resize((1179, 2556), Image.Resampling.LANCZOS)
    img_61.save(os.path.join(OUT_61, filename), 'PNG', optimize=True)
    img_63 = img_67.resize((1206, 2622), Image.Resampling.LANCZOS)
    img_63.save(os.path.join(OUT_63, filename), 'PNG', optimize=True)
    img_67.save(os.path.join(OUT_67, filename), 'PNG', optimize=True)


# ==============================================================================
# SCREENSHOT 1: Real-Time Incident Feed (Raw iPhone Capture)
# ==============================================================================
img1, d1 = create_raw_iphone_screen(
    "Reweu Partners",
    right_pill="All Branches  v",
    active_nav=0
)

# Search Bar
cy = 315
d1.rounded_rectangle([48, cy, 1242, cy + 98], radius=24, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
# Search magnifier icon
d1.ellipse([82, cy + 28, 116, cy + 62], outline=TEXT_MUTED, width=5)
d1.line([(112, cy + 58), (126, cy + 72)], fill=TEXT_MUTED, width=5)
d1.text((150, cy + 28), "Search customer, order # or branch...", fill=TEXT_MUTED, font=f_body)

# Filter Chips
cy += 130
chips = [("All (12)", True), ("Critical (3)", False), ("Open (5)", False), ("Resolved (4)", False)]
cx = 48
for label, active in chips:
    bbox = d1.textbbox((0, 0), label, font=f_small)
    cw = (bbox[2] - bbox[0]) + 64
    bg = BRAND_TEAL if active else CARD_WHITE
    fg = TEXT_WHITE if active else TEXT_SLATE
    d1.rounded_rectangle([cx, cy, cx + cw, cy + 74], radius=37, fill=bg, outline=BRAND_TEAL if active else BORDER_LIGHT, width=2)
    d1.text((cx + 32, cy + 19), label, fill=fg, font=f_small)
    cx += cw + 20

# 4 Real Incident Cards
cards = [
    {
        "id": "#INC-1082", "branch": "Downtown Branch", "time": "2m ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Farhan Ahmed", "rating": "★ 1.0   Food Quality & Temperature",
        "l1": "\"Ordered the family platter for guests, food arrived cold",
        "l2": "and specialty dipping sauces were missing from the bag.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    },
    {
        "id": "#INC-1081", "branch": "Gulberg Flagship", "time": "14m ago",
        "sev": "HIGH", "sev_fg": AMBER_HIGH, "sev_bg": AMBER_BG,
        "cust": "Sara Malik", "rating": "★ 2.0   Slow Table Service",
        "l1": "\"Waited 40 minutes for table service during lunch hour.",
        "l2": "Staff seemed overwhelmed and forgot our drinks.\"",
        "status": "In Review", "btn_bg": (224, 242, 241), "btn_fg": BRAND_TEAL
    },
    {
        "id": "#INC-1079", "branch": "DHA Phase 5", "time": "48m ago",
        "sev": "RESOLVED", "sev_fg": GREEN_OK, "sev_bg": GREEN_BG,
        "cust": "Usman Tariq", "rating": "★ 1.0   Recovered (PKR 1,500 Voucher)",
        "l1": "\"Branch manager called within 5 minutes, apologized and",
        "l2": "issued a PKR 1,500 recovery voucher for our next visit.\"",
        "status": "Resolved", "btn_bg": GREEN_BG, "btn_fg": GREEN_OK
    },
    {
        "id": "#INC-1076", "branch": "Mall Road Outlet", "time": "2h ago",
        "sev": "CRITICAL", "sev_fg": RED_CRIT, "sev_bg": RED_BG,
        "cust": "Ayesha Siddiqui", "rating": "★ 1.0   Wrong Order Delivered",
        "l1": "\"Received spicy chicken instead of mild kids platter.",
        "l2": "Needs immediate replacement order dispatched.\"",
        "status": "Acknowledge", "btn_bg": BRAND_TEAL, "btn_fg": TEXT_WHITE
    }
]

cy += 108
for c in cards:
    ch = 460
    d1.rounded_rectangle([48, cy, 1242, cy + ch], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
    d1.rounded_rectangle([48, cy + 28, 60, cy + ch - 28], radius=6, fill=c["sev_fg"])

    d1.text((92, cy + 32), f"{c['id']}  •  {c['branch']}", fill=TEXT_SLATE, font=f_small)
    d1.rounded_rectangle([1242 - 245, cy + 26, 1242 - 42, cy + 78], radius=16, fill=c["sev_bg"])
    draw_centered_text(d1, cy + 35, c["sev"], f_tiny, c["sev_fg"], center_x=1242 - 143)

    d1.text((92, cy + 90), c["cust"], fill=TEXT_DARK, font=f_h2)
    d1.text((1242 - 170, cy + 98), c["time"], fill=TEXT_MUTED, font=f_small)

    d1.text((92, cy + 150), c["rating"], fill=c["sev_fg"], font=f_semi)

    d1.text((92, cy + 206), c["l1"], fill=TEXT_SLATE, font=f_body)
    d1.text((92, cy + 252), c["l2"], fill=TEXT_SLATE, font=f_body)

    d1.line([(92, cy + 325), (1200, cy + 325)], fill=DIVIDER, width=2)
    d1.text((92, cy + 368), "Tap to view timeline & contact guest", fill=TEXT_MUTED, font=f_tiny)
    d1.rounded_rectangle([1242 - 310, cy + 346, 1242 - 42, cy + 430], radius=22, fill=c["btn_bg"])
    draw_centered_text(d1, cy + 368, c["status"], f_semi, c["btn_fg"], center_x=1242 - 176)

    cy += ch + 32

save_both_ios_sizes(img1, 'ios_screenshot_1_feed.png')


# ==============================================================================
# SCREENSHOT 2: Incident Detail & Customer Contact (Raw iPhone Capture)
# ==============================================================================
img2, d2 = create_raw_iphone_screen(
    "Incident #INC-1082",
    right_pill="CRITICAL",
    right_pill_bg=RED_CRIT,
    active_nav=0,
    back_btn=True
)

cy = 315
# Card 1: Customer Contact Card
d2.rounded_rectangle([48, cy, 1242, cy + 520], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d2.text((88, cy + 38), "CUSTOMER CONTACT DETAILS", fill=TEXT_MUTED, font=f_tiny)
d2.text((88, cy + 88), "Farhan Ahmed", fill=TEXT_DARK, font=f_h1)
d2.text((88, cy + 178), "+92 300 8492011   •   farhan.a@gmail.com", fill=TEXT_SLATE, font=f_semi)
d2.text((88, cy + 232), "Downtown Branch   •   Order #4892 (Dine-in / Takeaway)", fill=BRAND_CYAN, font=f_small)

btns = [
    ("Call Guest", (37, 99, 235)),
    ("WhatsApp", (22, 163, 74)),
    ("Send Email", (71, 85, 105))
]
bw = 344
bx = 88
for label, col in btns:
    d2.rounded_rectangle([bx, cy + 305, bx + bw, cy + 412], radius=24, fill=col)
    draw_centered_text(d2, cy + 338, label, f_bold, TEXT_WHITE, center_x=bx + bw // 2)
    bx += bw + 38

d2.text((88, cy + 445), "Privacy Shield: Customer contact details hidden in iOS App Switcher", fill=TEXT_MUTED, font=f_tiny)

# Card 2: Low-Score Review Breakdown
cy += 558
d2.rounded_rectangle([48, cy, 1242, cy + 610], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d2.text((88, cy + 38), "CUSTOMER FEEDBACK & RATING", fill=TEXT_MUTED, font=f_tiny)
d2.text((88, cy + 90), "★ 1.0 / 5.0  —  Food Quality & Accuracy", fill=RED_CRIT, font=f_bold)

d2.rounded_rectangle([88, cy + 165, 1202, cy + 425], radius=24, fill=SCREEN_BG)
d2.text((120, cy + 200), "\"Ordered the family platter for our dinner guests.", fill=TEXT_DARK, font=f_body)
d2.text((120, cy + 255), "The food arrived completely cold and all specialty", fill=TEXT_DARK, font=f_body)
d2.text((120, cy + 310), "dipping sauces were missing from the delivery bag.\"", fill=TEXT_DARK, font=f_body)

d2.text((88, cy + 465), "Assigned Staff: Bilal H. (Shift Supervisor)", fill=TEXT_SLATE, font=f_semi)
d2.text((88, cy + 522), "SLA Target: Respond within 15 mins (11m remaining)", fill=AMBER_HIGH, font=f_semi)

# Card 3: Internal Notes & Timeline
cy += 648
d2.rounded_rectangle([48, cy, 1242, cy + 960], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d2.text((88, cy + 38), "INTERNAL TEAM NOTES & AUDIT TIMELINE", fill=TEXT_MUTED, font=f_tiny)

timeline = [
    ("10:14 AM  —  Incident raised from 1★ customer review", "Automatically routed to Downtown Branch manager", TEXT_SLATE),
    ("10:16 AM  —  Acknowledged by Branch Manager", "Ali Raza took ownership of this incident", BRAND_TEAL),
    ("10:19 AM  —  Internal Note Added", "Called guest, apologized & dispatched hot replacement", GREEN_OK)
]
ty = cy + 108
for line_top, line_sub, col in timeline:
    d2.ellipse([88, ty + 8, 114, ty + 34], fill=col)
    d2.text((144, ty), line_top, fill=TEXT_DARK, font=f_semi)
    d2.text((144, ty + 46), line_sub, fill=TEXT_SLATE, font=f_body)
    ty += 126

# Note input box (500 char cap)
d2.rounded_rectangle([88, cy + 510, 1202, cy + 720], radius=24, fill=SCREEN_BG, outline=BORDER_LIGHT, width=3)
d2.text((120, cy + 545), "Add internal triage note for branch staff...", fill=TEXT_MUTED, font=f_body)
d2.text((1000, cy + 660), "0 / 500 chars", fill=TEXT_MUTED, font=f_tiny)

# Resolve CTA Button
d2.rounded_rectangle([88, cy + 770, 1202, cy + 905], radius=28, fill=BRAND_TEAL)
draw_centered_text(d2, cy + 814, "Resolve Incident & Issue Voucher", f_h2, TEXT_WHITE, center_x=645)

save_both_ios_sizes(img2, 'ios_screenshot_2_triage.png')


# ==============================================================================
# SCREENSHOT 3: Service Recovery Vouchers (Raw iPhone Capture)
# ==============================================================================
img3, d3 = create_raw_iphone_screen(
    "Resolve #INC-1082",
    active_nav=0,
    back_btn=True
)

cy = 315
d3.rounded_rectangle([48, cy, 1242, 2490], radius=36, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)

d3.text((92, cy + 54), "1. Select Resolution Status", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([92, cy + 135, 625, cy + 310], radius=26, fill=GREEN_BG, outline=GREEN_OK, width=3)
d3.text((130, cy + 172), "Resolved (Selected)", fill=GREEN_OK, font=f_bold)
d3.text((130, cy + 228), "Issue fixed with customer", fill=GREEN_OK, font=f_small)

d3.rounded_rectangle([665, cy + 135, 1198, cy + 310], radius=26, fill=SCREEN_BG, outline=BORDER_LIGHT, width=2)
d3.text((705, cy + 172), "Acknowledged", fill=TEXT_SLATE, font=f_bold)
d3.text((705, cy + 228), "Under investigation", fill=TEXT_MUTED, font=f_small)

# Voucher Section (Max PKR 50,000 limit)
d3.text((92, cy + 385), "2. Service Recovery Voucher", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([92, cy + 465, 1198, cy + 985], radius=32, fill=(240, 253, 250), outline=BRAND_CYAN, width=3)
d3.text((135, cy + 515), "Attach Goodwill Compensation Voucher", fill=BRAND_TEAL, font=f_bold)
# iOS Toggle Switch
d3.rounded_rectangle([1030, cy + 505, 1150, cy + 575], radius=35, fill=GREEN_OK)
d3.ellipse([1086, cy + 513, 1142, cy + 569], fill=TEXT_WHITE)

d3.text((135, cy + 615), "Voucher Amount (PKR)   •   Max Limit: PKR 50,000", fill=TEXT_SLATE, font=f_small)
d3.rounded_rectangle([135, cy + 675, 1155, cy + 835], radius=24, fill=CARD_WHITE, outline=BRAND_TEAL, width=3)
d3.text((175, cy + 716), "PKR   1,500", fill=BRAND_TEAL, font=f_h1)
d3.text((880, cy + 738), "Valid for 30 days", fill=GREEN_OK, font=f_small)
d3.text((135, cy + 885), "Voucher code is sent automatically to the customer upon resolution", fill=BRAND_TEAL, font=f_small)

# Top-aligned Resolution Summary (500 char cap)
d3.text((92, cy + 1065), "3. Resolution Summary (Required)", fill=TEXT_DARK, font=f_h2)
d3.rounded_rectangle([92, cy + 1145, 1198, cy + 1835], radius=30, fill=SCREEN_BG, outline=BORDER_LIGHT, width=3)
summary_lines = [
    "Spoke with Mr. Farhan directly on phone and apologized",
    "for the cold platter and missing dipping sauces.",
    "",
    "Dispatched a fresh hot replacement order via express",
    "rider and issued a PKR 1,500 recovery voucher for his",
    "next family visit. Customer was very appreciative and",
    "thanked the branch team for the prompt follow-up."
]
sy_text = cy + 1195
for line in summary_lines:
    d3.text((135, sy_text), line, fill=TEXT_DARK, font=f_body)
    sy_text += 56

d3.text((955, cy + 1765), "286 / 500 chars", fill=TEXT_MUTED, font=f_small)

# Confirm CTA
d3.rounded_rectangle([92, cy + 1920, 1198, cy + 2075], radius=32, fill=BRAND_TEAL)
draw_centered_text(d3, cy + 1968, "Confirm Resolution & Send Voucher", f_h2, TEXT_WHITE, center_x=645)

save_both_ios_sizes(img3, 'ios_screenshot_3_recovery.png')


# ==============================================================================
# SCREENSHOT 4: Multi-Branch & Staff Analytics (Raw iPhone Capture)
# ==============================================================================
img4, d4 = create_raw_iphone_screen(
    "Branch Analytics",
    right_pill="Last 30 Days  v",
    active_nav=1
)

cy = 315
kpis = [
    ("48", "Total Incidents", "-18% vs prior 30d", BRAND_TEAL),
    ("96.4%", "Resolution Rate", "+4.2% improvement", GREEN_OK),
    ("11m", "Avg Time to Review", "Within 15m SLA target", BRAND_CYAN),
    ("34m", "Avg Time to Resolve", "Fastest: Downtown", AMBER_HIGH)
]
card_w = 576
card_h = 310
for i, (val, title, sub, col) in enumerate(kpis):
    row = i // 2
    col_idx = i % 2
    kx = 48 + col_idx * (card_w + 42)
    ky = cy + row * (card_h + 36)
    d4.rounded_rectangle([kx, ky, kx + card_w, ky + card_h], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
    d4.text((kx + 44, ky + 38), val, fill=col, font=f_h1)
    d4.text((kx + 44, ky + 148), title, fill=TEXT_DARK, font=f_bold)
    d4.text((kx + 44, ky + 212), sub, fill=TEXT_MUTED, font=f_small)

# Daily Severity Trend Bar Chart
cy += 700
d4.rounded_rectangle([48, cy, 1242, cy + 640], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d4.text((88, cy + 38), "DAILY INCIDENT VOLUME & SEVERITY TREND", fill=TEXT_MUTED, font=f_tiny)

days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
bars = [(220, 80), (160, 50), (280, 110), (190, 65), (320, 125), (240, 75), (130, 40)]
bx = 112
base_y = cy + 520
for d_lbl, (h_tot, h_crit) in zip(days, bars):
    d4.rounded_rectangle([bx, base_y - h_tot, bx + 86, base_y], radius=16, fill=BRAND_TEAL)
    d4.rounded_rectangle([bx, base_y - h_crit, bx + 86, base_y], radius=16, fill=BRAND_GOLD)
    draw_centered_text(d4, base_y + 26, d_lbl, f_small, TEXT_SLATE, center_x=bx + 43)
    bx += 156

# Branch Leaderboard Table
cy += 680
d4.rounded_rectangle([48, cy, 1242, 2490], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d4.text((88, cy + 38), "BRANCH RESOLUTION LEADERBOARD", fill=TEXT_MUTED, font=f_tiny)

branches = [
    ("1. Downtown Flagship", "18 incidents   •   Avg 9m response", "98% Resolved", GREEN_OK, GREEN_BG),
    ("2. Gulberg Main", "14 incidents   •   Avg 12m response", "95% Resolved", GREEN_OK, GREEN_BG),
    ("3. DHA Phase 5", "11 incidents   •   Avg 14m response", "91% Resolved", BRAND_TEAL, (224, 242, 241)),
    ("4. Mall Road Express", "5 incidents    •   Avg 19m response", "86% Resolved", AMBER_HIGH, AMBER_BG)
]
by = cy + 115
for b_name, b_sub, b_rate, fg, bg in branches:
    d4.text((88, by), b_name, fill=TEXT_DARK, font=f_bold)
    d4.text((88, by + 54), b_sub, fill=TEXT_SLATE, font=f_small)
    d4.rounded_rectangle([1242 - 335, by + 8, 1242 - 80, by + 86], radius=20, fill=bg)
    draw_centered_text(d4, by + 28, b_rate, f_small, fg, center_x=1242 - 207)
    if by < cy + 560:
        d4.line([(88, by + 132), (1162, by + 132)], fill=DIVIDER, width=2)
    by += 168

save_both_ios_sizes(img4, 'ios_screenshot_4_analytics.png')


# ==============================================================================
# SCREENSHOT 5: Face ID & Privacy Settings (Raw iPhone Capture)
# ==============================================================================
img5, d5 = create_raw_iphone_screen(
    "Profile & Security",
    active_nav=2
)

cy = 315
# Partner Profile Card
d5.rounded_rectangle([48, cy, 1242, cy + 340], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d5.ellipse([92, cy + 68, 256, cy + 232], fill=BRAND_TEAL)
draw_centered_text(d5, cy + 114, "AP", f_nav_title, BRAND_GOLD, center_x=174)
d5.text((298, cy + 68), "Arsalan Peerzada", fill=TEXT_DARK, font=f_h2)
d5.text((298, cy + 136), "Business Owner  •  Reweu Hospitality Group", fill=TEXT_SLATE, font=f_semi)
d5.rounded_rectangle([298, cy + 206, 710, cy + 272], radius=16, fill=GREEN_BG)
d5.text((328, cy + 220), "Verified Partner Account", fill=GREEN_OK, font=f_small)

# Security & Privacy Controls
cy += 380
d5.rounded_rectangle([48, cy, 1242, cy + 1120], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d5.text((88, cy + 42), "IOS SECURITY & PRIVACY CONTROLS", fill=TEXT_MUTED, font=f_tiny)

settings = [
    ("Face ID / Touch ID App Lock", "Locks automatically after 60s in background"),
    ("App-Switcher Privacy Shield", "Covers customer details in iOS multitasking view"),
    ("Critical Incident Push Alerts (APNs)", "Time-sensitive alert sound for 1★ & 2★ reviews"),
    ("Keychain-Backed Offline Cache", "Encrypted local storage when network drops")
]
sy = cy + 128
for title, sub in settings:
    d5.text((88, sy), title, fill=TEXT_DARK, font=f_bold)
    d5.text((88, sy + 58), sub, fill=TEXT_SLATE, font=f_body)
    d5.rounded_rectangle([1040, sy + 14, 1168, sy + 88], radius=37, fill=GREEN_OK)
    d5.ellipse([1100, sy + 22, 1160, sy + 82], fill=TEXT_WHITE)
    d5.line([(88, sy + 158), (1168, sy + 158)], fill=DIVIDER, width=2)
    sy += 235

# Language & Sign Out Card
cy += 1160
d5.rounded_rectangle([48, cy, 1242, 2490], radius=32, fill=CARD_WHITE, outline=BORDER_LIGHT, width=3)
d5.text((88, cy + 42), "LANGUAGE & LOCALIZATION", fill=TEXT_MUTED, font=f_tiny)
d5.text((88, cy + 102), "Switch instantly between English and Urdu (RTL)", fill=TEXT_SLATE, font=f_body)

d5.rounded_rectangle([88, cy + 190, 620, cy + 345], radius=24, fill=(224, 242, 241), outline=BRAND_TEAL, width=3)
draw_centered_text(d5, cy + 245, "English (Active)", f_bold, BRAND_TEAL, center_x=354)

d5.rounded_rectangle([660, cy + 190, 1192, cy + 345], radius=24, fill=SCREEN_BG, outline=BORDER_LIGHT, width=2)
draw_centered_text(d5, cy + 245, "Urdu (Nastaliq RTL)", f_bold, TEXT_SLATE, center_x=926)

d5.rounded_rectangle([88, cy + 415, 1192, cy + 560], radius=24, fill=RED_BG, outline=RED_CRIT, width=2)
draw_centered_text(d5, cy + 465, "Sign Out of Partner Account", f_bold, RED_CRIT, center_x=645)

save_both_ios_sizes(img5, 'ios_screenshot_5_security.png')


# ==============================================================================
# NEW APP STORE CONNECT ASSETS:
# 1. Header Asset (3840 x 1648 px)
# 2. Search Results Asset (1920 x 1280 px)
# 3. Universal Header/Search Asset (5244 x 2850 px)
# ==============================================================================
def create_promo_banner(w, h, out_path):
    banner = Image.new('RGB', (w, h), BRAND_DARK)
    bdraw = ImageDraw.Draw(banner)
    for y in range(h):
        ratio = y / h
        g = int(34 + (58 - 34) * ratio)
        b = int(42 + (68 - 42) * ratio)
        bdraw.line([(0, y), (w, y)], fill=(0, g, b))

    # Scale relative to width so narrower aspect ratios (like 3:2 1920x1280) never overlap
    scale_f = min(h / 1280.0, w / 2800.0)
    lw = int(520 * scale_f)
    lh = int(logo_crop.size[1] * (lw / logo_crop.size[0]))
    logo_b = logo_crop.resize((lw, lh), Image.Resampling.LANCZOS)
    left_x = int(w * 0.06)
    top_y = int(h * 0.22)
    banner.paste(logo_b, (left_x, top_y), logo_b)

    f_b_title = ImageFont.truetype('assets/fonts/Outfit-Bold.ttf', int(58 * scale_f))
    f_b_sub = ImageFont.truetype('assets/fonts/PlusJakartaSans-Medium.ttf', int(28 * scale_f))
    f_b_chip = ImageFont.truetype('assets/fonts/Outfit-SemiBold.ttf', int(24 * scale_f))

    bdraw.text((left_x, top_y + lh + int(50 * scale_f)), "Critical Incident Management", fill=TEXT_WHITE, font=f_b_title)
    bdraw.text((left_x, top_y + lh + int(125 * scale_f)), "for Your Business & Branches", fill=BRAND_GOLD, font=f_b_title)
    bdraw.text((left_x, top_y + lh + int(220 * scale_f)), "Real-time review triage, instant guest contact & recovery vouchers.", fill=(203, 213, 225), font=f_b_sub)

    chips = ["Real-Time Alerts", "Recovery Vouchers", "Branch Analytics", "Face ID Lock"]
    cx = left_x
    cy = top_y + lh + int(310 * scale_f)
    ch_h = int(58 * scale_f)
    for ch in chips:
        cb = bdraw.textbbox((0, 0), ch, font=f_b_chip)
        cw = (cb[2] - cb[0]) + int(48 * scale_f)
        bdraw.rounded_rectangle([cx, cy, cx + cw, cy + ch_h], radius=ch_h // 2, fill=(0, 68, 80), outline=BRAND_GOLD, width=max(2, int(2 * scale_f)))
        bdraw.text((cx + int(24 * scale_f), cy + int(13 * scale_f)), ch, fill=TEXT_WHITE, font=f_b_chip)
        cx += cw + int(18 * scale_f)

    # Right side: Showcase two iPhone screens side-by-side
    s1 = img1.copy()
    s3 = img3.copy()
    pw = int(min(h * 0.34, w * 0.165))
    ph = int(pw * (2796 / 1290))
    s1_res = s1.resize((pw, ph), Image.Resampling.LANCZOS)
    s3_res = s3.resize((pw, ph), Image.Resampling.LANCZOS)

    gap = int(28 * scale_f)
    rx1 = w - int(w * 0.06) - pw * 2 - gap
    ry1 = (h - ph) // 2 + int(35 * scale_f)
    rx2 = rx1 + pw + gap
    ry2 = (h - ph) // 2 - int(25 * scale_f)

    pad = max(6, int(8 * scale_f))
    bdraw.rounded_rectangle([rx1 - pad, ry1 - pad, rx1 + pw + pad, ry1 + ph + pad], radius=int(28 * scale_f), fill=(15, 23, 42), outline=(100, 116, 139), width=2)
    banner.paste(s1_res, (rx1, ry1))

    bdraw.rounded_rectangle([rx2 - pad, ry2 - pad, rx2 + pw + pad, ry2 + ph + pad], radius=int(28 * scale_f), fill=(15, 23, 42), outline=(100, 116, 139), width=2)
    banner.paste(s3_res, (rx2, ry2))

    banner.save(out_path, 'PNG', optimize=True)
    print("Saved promo banner:", out_path, banner.size)


create_promo_banner(3840, 1646, os.path.join(OUT_DIR, 'header_3840x1646.png'))
create_promo_banner(1920, 1280, os.path.join(OUT_DIR, 'search_results_1920x1280.png'))
create_promo_banner(5244, 2950, os.path.join(OUT_DIR, 'header_and_search_5244x2950.png'))

print("All raw iPhone screenshots (with Apple status bar & battery icons) and Header/Search Results assets created!")
