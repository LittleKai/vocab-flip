import json
import datetime

cards_data = [
    # Airport (16 cards)
    ("passport", "/ˈpæspɔːrt/", "hộ chiếu", "Can I see your passport, please?"),
    ("boarding pass", "/ˈbɔːrdɪŋ pæs/", "thẻ lên máy bay", "Please have your boarding pass ready."),
    ("flight", "/flaɪt/", "chuyến bay", "My flight is delayed by two hours."),
    ("luggage", "/ˈlʌɡɪdʒ/", "hành lý", "Where can I claim my luggage?"),
    ("baggage claim", "/ˈbæɡɪdʒ kleɪm/", "nơi nhận hành lý", "Follow the signs to baggage claim."),
    ("customs", "/ˈkʌstəmz/", "hải quan", "You have to go through customs."),
    ("departure", "/dɪˈpɑːrtʃər/", "khởi hành", "The departure time is 8:00 AM."),
    ("arrival", "/əˈraɪvl/", "đến nơi", "Arrivals are on the lower level."),
    ("gate", "/ɡeɪt/", "cổng lên máy bay", "Our flight departs from Gate 12."),
    ("terminal", "/ˈtɜːrmɪnl/", "nhà ga", "Which terminal does the flight leave from?"),
    ("security check", "/sɪˈkjʊrəti tʃek/", "kiểm tra an ninh", "Please remove your shoes at the security check."),
    ("carry-on", "/ˈkæri ɑːn/", "hành lý xách tay", "Is this bag small enough for a carry-on?"),
    ("layover", "/ˈleɪoʊvər/", "thời gian quá cảnh", "We have a two-hour layover in Tokyo."),
    ("check-in", "/ˈtʃek ɪn/", "làm thủ tục", "Check-in opens three hours before departure."),
    ("ticket", "/ˈtɪkɪt/", "vé", "Here is my return ticket."),
    ("aisle seat", "/aɪl siːt/", "ghế sát lối đi", "I prefer an aisle seat so I can stretch my legs."),

    # Hotel (16 cards)
    ("reservation", "/ˌrezərˈveɪʃn/", "đặt phòng", "I have a reservation under the name John."),
    ("reception", "/rɪˈsepʃn/", "quầy lễ tân", "Leave your key at reception."),
    ("check out", "/tʃek aʊt/", "trả phòng", "What time do we need to check out?"),
    ("single room", "/ˈsɪŋɡl ruːm/", "phòng đơn", "I'd like to book a single room."),
    ("double room", "/ˈdʌbl ruːm/", "phòng đôi", "Do you have a double room available?"),
    ("key card", "/kiː kɑːrd/", "thẻ khóa phòng", "I lost my key card."),
    ("elevator", "/ˈelɪveɪtər/", "thang máy", "The elevator is at the end of the hall."),
    ("lobby", "/ˈlɑːbi/", "sảnh", "I will meet you in the lobby."),
    ("breakfast included", "/ˈbrekfəst ɪnˈkluːdɪd/", "bao gồm bữa sáng", "Is breakfast included in the price?"),
    ("air conditioning", "/er kənˈdɪʃənɪŋ/", "máy lạnh", "The air conditioning in my room isn't working."),
    ("towel", "/ˈtaʊəl/", "khăn tắm", "Could I have an extra towel, please?"),
    ("blanket", "/ˈblæŋkɪt/", "chăn, mền", "It's cold, can I get another blanket?"),
    ("room service", "/ruːm ˈsɜːrvɪs/", "dịch vụ phòng", "Let's order some room service."),
    ("housekeeping", "/ˈhaʊskiːpɪŋ/", "dọn phòng", "Housekeeping will clean the room every morning."),
    ("deposit", "/dɪˈpɑːzɪt/", "tiền đặt cọc", "You need to pay a deposit of $50."),
    ("wifi password", "/ˈwaɪfaɪ ˈpæswɜːrd/", "mật khẩu wifi", "What is the wifi password?"),

    # Directions / Transportation (16 cards)
    ("map", "/mæp/", "bản đồ", "Can you show me on the map?"),
    ("bus stop", "/bʌs stɑːp/", "trạm xe buýt", "Is there a bus stop near here?"),
    ("train station", "/treɪn ˈsteɪʃn/", "ga xe lửa", "How do I get to the train station?"),
    ("subway", "/ˈsʌbweɪ/", "tàu điện ngầm", "The subway is the fastest way to travel."),
    ("taxi stand", "/ˈtæksi stænd/", "điểm đón taxi", "Where is the nearest taxi stand?"),
    ("straight ahead", "/streɪt əˈhed/", "đi thẳng", "Go straight ahead for two blocks."),
    ("turn left", "/tɜːrn left/", "rẽ trái", "Turn left at the next traffic light."),
    ("turn right", "/tɜːrn raɪt/", "rẽ phải", "Turn right at the corner."),
    ("intersection", "/ˈɪntərsekʃn/", "ngã tư, giao lộ", "Go past the intersection."),
    ("ticket office", "/ˈtɪkɪt ˈɑːfɪs/", "phòng bán vé", "You can buy passes at the ticket office."),
    ("schedule", "/ˈskedʒuːl/", "lịch trình", "Do you have the bus schedule?"),
    ("platform", "/ˈplætfɔːrm/", "sân ga", "Which platform does the train to London leave from?"),
    ("fare", "/fer/", "giá vé", "How much is the fare to the airport?"),
    ("distance", "/ˈdɪstəns/", "khoảng cách", "What is the distance to the museum?"),
    ("lost", "/lɔːst/", "lạc đường", "I think we are lost."),
    ("address", "/əˈdres/", "địa chỉ", "Can you write down the address for me?"),

    # Emergency / Health (16 cards)
    ("help", "/help/", "cứu giúp", "Help! I need assistance."),
    ("hospital", "/ˈhɑːspɪtl/", "bệnh viện", "Take me to the nearest hospital."),
    ("doctor", "/ˈdɑːktər/", "bác sĩ", "I need to see a doctor immediately."),
    ("pharmacy", "/ˈfɑːrməsi/", "hiệu thuốc", "Where is the nearest pharmacy?"),
    ("police", "/pəˈliːs/", "cảnh sát", "Call the police!"),
    ("stolen", "/ˈstoʊlən/", "bị đánh cắp", "My wallet has been stolen."),
    ("lost passport", "/lɔːst ˈpæspɔːrt/", "mất hộ chiếu", "I have lost my passport."),
    ("embassy", "/ˈembəsi/", "đại sứ quán", "I need to contact my embassy."),
    ("pain", "/peɪn/", "đau đớn", "I have a terrible pain in my stomach."),
    ("fever", "/ˈfiːvər/", "sốt", "He has a high fever."),
    ("medicine", "/ˈmedɪsn/", "thuốc", "What kind of medicine do you need?"),
    ("allergy", "/ˈælərdʒi/", "dị ứng", "I have a severe peanut allergy."),
    ("emergency", "/ɪˈmɜːrdʒənsi/", "trường hợp khẩn cấp", "This is an emergency."),
    ("accident", "/ˈæksɪdənt/", "tai nạn", "There has been a car accident."),
    ("insurance", "/ɪnˈʃʊrəns/", "bảo hiểm", "Do you have travel insurance?"),
    ("ambulance", "/ˈæmbjələns/", "xe cứu thương", "Please call an ambulance."),

    # Restaurant / Food (16 cards)
    ("menu", "/ˈmenjuː/", "thực đơn", "Could we see the menu, please?"),
    ("order", "/ˈɔːrdər/", "gọi món", "Are you ready to order?"),
    ("bill", "/bɪl/", "hóa đơn", "Could we have the bill, please?"),
    ("tip", "/tɪp/", "tiền boa", "It is customary to leave a 15% tip."),
    ("vegetarian", "/ˌvedʒəˈteriən/", "người ăn chay", "Do you have vegetarian dishes?"),
    ("spicy", "/ˈspaɪsi/", "cay", "Is this food very spicy?"),
    ("water", "/ˈwɔːtər/", "nước", "Can I have a glass of tap water?"),
    ("appetizer", "/ˈæpɪtaɪzər/", "món khai vị", "Let's share an appetizer."),
    ("main course", "/meɪn kɔːrs/", "món chính", "For the main course, I will have steak."),
    ("dessert", "/dɪˈzɜːrt/", "món tráng miệng", "Would you like to look at the dessert menu?"),
    ("napkin", "/ˈnæpkɪn/", "khăn ăn", "Could I get an extra napkin?"),
    ("delicious", "/dɪˈlɪʃəs/", "ngon miệng", "The meal was absolutely delicious."),
    ("takeaway", "/ˈteɪkəweɪ/", "mang về", "Can I get this as a takeaway?"),
    ("fork", "/fɔːrk/", "nĩa", "Excuse me, I dropped my fork."),
    ("spoon", "/spuːn/", "muỗng", "Do you have a spoon for the soup?"),
    ("knife", "/naɪf/", "dao", "I need a knife to cut this meat.")
]

cards = []
for front, phonetic, back, example in cards_data:
    cards.append({
        "front": front,
        "front_phonetic": phonetic,
        "back": back,
        "examples": [example],
        "notes": "",
        "share_image": True,
        "tags": ["travel"]
    })

deck_json = {
    "version": "1.0",
    "exported_at": datetime.datetime.now().isoformat() + "Z",
    "decks": [
        {
            "name": "English Travel Essentials",
            "description": "Tổng hợp các từ vựng và cụm từ thông dụng nhất tại sân bay, khách sạn, hỏi đường, trường hợp khẩn cấp và nhà hàng dành cho người chuẩn bị đi du lịch nước ngoài.",
            "source_language": "en",
            "target_language": "vi",
            "show_back_first": False,
            "front_fields": ["word", "phonetic"],
            "back_fields": ["meaning", "example", "notes"],
            "image_display_mode": "none",
            "image_path": "",
            "auto_play_tts_on_flip": True,
            "category": "travel",
            "tags": ["english", "travel", "essentials"],
            "cards": cards
        }
    ]
}

with open("english_travel_essentials.json", "w", encoding="utf-8") as f:
    json.dump(deck_json, f, ensure_ascii=False, indent=2)

print("Created english_travel_essentials.json with", len(cards), "cards.")
