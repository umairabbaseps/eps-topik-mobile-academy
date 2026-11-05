// EPS TOPIK Pro Pakistan — original lesson content.
// Titles/topics only for the HRD Korea Standard Korean Textbook (2024 revised
// edition). No textbook text and no real test questions are copied here.
// Course order: Preliminary (Hangul I-III + Greetings), Units 1-30 Book 1
// daily life, Units 31-60 Book 2 workplace. In force for tests from 1 Aug 2025.

class Unit {
  final int n;
  final String ko;
  final String en;
  final String grammar;
  final String book; // '1' daily life, '2' workplace, 'P' preliminary
  const Unit(this.n, this.ko, this.en, this.grammar, this.book);
}

const List<Unit> units = [
  Unit(0, '한글 익히기 I–III + 인사', 'Hangul I–III + Greetings', 'Vowels, consonants, final consonants (받침)', 'P'),
  Unit(1, '자기소개', 'Self Introduction', '은/는, 이에요/예요', '1'),
  Unit(2, '생활용품', 'Daily Necessities', '이/가, 있어요/없어요', '1'),
  Unit(3, '위치와 장소', 'Locations and Places', '에 (place), -아요/어요', '1'),
  Unit(4, '동작과 사물', 'Actions and Objects', '을/를, -아요/어요', '1'),
  Unit(5, '날짜와 요일', 'Dates and Days', '에 (time), -았/었-', '1'),
  Unit(6, '하루 일과', 'Daily Routine', '에서, -(스)ㅂ니까?', '1'),
  Unit(7, '계절과 날씨', 'Seasons and Weather', '안, -(으)시-, -고', '1'),
  Unit(8, '가족과 친구', 'Family and Friends', '-주세요, -고', '1'),
  Unit(9, '음식 주문', 'Ordering Food', '하고', '1'),
  Unit(10, '물건 구입', 'Shopping', '-네요, -아/어 주세요', '1'),
  Unit(11, '집안일', 'Household Chores', '-아야/어야 되다', '1'),
  Unit(12, '대중교통', 'Public Transportation', '(으)로, -아서/어서', '1'),
  Unit(13, '주말 활동', 'Weekend Activities', '-(으)ㄹ 거예요, 못', '1'),
  Unit(14, '길 찾기', 'Getting Directions', '(으)로, -(으)세요', '1'),
  Unit(15, '옷차림', 'Clothing', '-(으)ㄴ, -고 있다', '1'),
  Unit(16, '집 구하기', 'Finding a House', '-고 싶다, -지만', '1'),
  Unit(17, '휴가', 'Vacation', '-(으)려고 하다', '1'),
  Unit(18, '취미', 'Hobbies', '-(으)ㄹ까요?, -아/어 보다', '1'),
  Unit(19, '요리', 'Cooking', '-아서/어서, -고 있다', '1'),
  Unit(20, '인터넷과 스마트폰', 'Internet and Smartphones', '-(으)ㄹ래요', '1'),
  Unit(21, '병원', 'Hospital', '-(으)면, -지 마세요', '1'),
  Unit(22, '약국', 'Pharmacy', '-(으)ㄴ 후에, -는데', '1'),
  Unit(23, '우체국', 'Post Office', '-지요?, -는데', '1'),
  Unit(24, '은행', 'Bank', '-(으)려고, -(으)면 되다', '1'),
  Unit(25, '외국인 근로자 지원 기관', 'Foreign Workers Support Centre', '-(으)러, -기 때문에', '1'),
  Unit(26, '한국의 주거 문화와 음식 문화', 'Housing and Food Culture', '-아도/어도 되다', '1'),
  Unit(27, '한국의 기념일', 'Commemorative Days', '-는, -아/어 봤다', '1'),
  Unit(28, '한국의 명절', 'Traditional Holidays', '-고 나서', '1'),
  Unit(29, '한국의 예절', 'Etiquette', '-(으)ㄹ 수 있다/없다', '1'),
  Unit(30, '한국의 대중문화', 'Popular Culture', '-(으)ㄴ 것 같다', '1'),
  Unit(31, '복장과 근무 태도', 'Dress and Work Attitude', '-아/어 보이다, -게', '2'),
  Unit(32, '회사 시설', 'Company Facilities', '-잖아요', '2'),
  Unit(33, '동료와의 관계', 'Colleagues', '-는/(으)ㄴ 편이다', '2'),
  Unit(34, '성희롱 및 성추행 예방', 'Preventing Sexual Harassment', '-던데요', '2'),
  Unit(35, '작업장 관리', 'Workplace Management', '-(으)ㅂ시다', '2'),
  Unit(36, '출하 관리', 'Shipping Management', '-겠-, -(으)ㄴ', '2'),
  Unit(37, '기계 가공', 'Machine Processing', '-아도/어도', '2'),
  Unit(38, '기계 조립', 'Machine Assembly', '-(으)면서', '2'),
  Unit(39, '금속 가공', 'Metal Processing', '-(으)라고 하다', '2'),
  Unit(40, '플라스틱 고무 성형', 'Plastic and Rubber Moulding', '-는 대신에', '2'),
  Unit(41, '섬유 제조', 'Textile Manufacturing', '-거나, -아야/어야', '2'),
  Unit(42, '가구 제작', 'Furniture Making', '-(으)ㄹ까 봐', '2'),
  Unit(43, '건축 시공', 'Building Construction', '-(으)ㄹ 텐데', '2'),
  Unit(44, '토목 시공', 'Civil Engineering', '-아야겠/어야겠-', '2'),
  Unit(45, '농작물 재배', 'Crop Cultivation', '-(으)ㄹ까 하다', '2'),
  Unit(46, '사육 관리', 'Livestock Management', '-(으)ㄴ 적이 있다/없다', '2'),
  Unit(47, '연안 어업과 양식', 'Coastal Fishing and Aquaculture', '-는 동안에', '2'),
  Unit(48, '선체 건조', 'Shipbuilding', '-아지다/어지다', '2'),
  Unit(49, '광물 자원 개발', 'Mineral Resource Development', '-던, -느라고', '2'),
  Unit(50, '산림 자원 조성', 'Forest Resource Development', '-다가', '2'),
  Unit(51, '숙박 서비스', 'Accommodation Services', '-았다가/었다가', '2'),
  Unit(52, '음식 조리', 'Food Cooking', '-았어야/었어야 했는데', '2'),
  Unit(53, '산업 안전 및 보건 표지', 'Safety Signs 1 (warning)', '-았더니/었더니', '2'),
  Unit(54, '산업 안전 및 보건 수칙', 'Safety Rules (evacuation)', '-도록 하다, -기 위해', '2'),
  Unit(55, '산업 안전 및 지시 표지', 'Safety Instruction Signs (PPE)', '-는 대로', '2'),
  Unit(56, '산업 재해 및 비상 상황', 'Accidents and Emergencies', '-(으)ㄹ 뻔하다, -자마자', '2'),
  Unit(57, '고용허가제', 'The EPS System', '-게 되다', '2'),
  Unit(58, '근로기준법', 'Labor Standards Act', '-뿐만 아니라', '2'),
  Unit(59, '출입국 관리법', 'Immigration Act', '-더라도', '2'),
  Unit(60, '근로자 보험', 'Worker Insurance', '-(으)려면', '2'),
];

/// Hangul vowels (21) and consonants (19), with a Roman sound hint.
const List<List<String>> vowels = [
  ['ㅏ','a'],['ㅑ','ya'],['ㅓ','eo'],['ㅕ','yeo'],['ㅗ','o'],['ㅛ','yo'],
  ['ㅜ','u'],['ㅠ','yu'],['ㅡ','eu'],['ㅣ','i'],['ㅐ','ae'],['ㅒ','yae'],
  ['ㅔ','e'],['ㅖ','ye'],['ㅘ','wa'],['ㅙ','wae'],['ㅚ','oe'],['ㅝ','wo'],
  ['ㅞ','we'],['ㅟ','wi'],['ㅢ','ui'],
];
const List<List<String>> consonants = [
  ['ㄱ','g/k'],['ㄴ','n'],['ㄷ','d/t'],['ㄹ','r/l'],['ㅁ','m'],['ㅂ','b/p'],
  ['ㅅ','s'],['ㅇ','ng / silent'],['ㅈ','j'],['ㅊ','ch'],['ㅋ','k'],
  ['ㅌ','t'],['ㅍ','p'],['ㅎ','h'],['ㄲ','kk'],['ㄸ','tt'],['ㅃ','pp'],
  ['ㅆ','ss'],['ㅉ','jj'],
];

/// Word builder steps: [letters, part, whole, meaning-en, meaning-roman-urdu]
const List<List<String>> wordBuilds = [
  ['ㄱ + ㅏ', '가', '가', 'go / family (가)', 'jaana / gharana'],
  ['ㅁ + ㅜ + ㄹ', '물', '물', 'water', 'paani'],
  ['ㅂ + ㅏ + ㅂ', '밥', '밥', 'rice / meal', 'chawal / khana'],
  ['ㅅ + ㅏ + ㄹ + ㅏ + ㅁ', '사람', '사람', 'person', 'aadmi / insaan'],
  ['ㅁ + ㅜ + ㄴ', '문', '문', 'door', 'darwaza'],
  ['ㅎ + ㅏ + ㄴ', '한', '한', 'one / Korea (한)', 'ek / Korea'],
  ['ㅈ + ㅜ + ㅅ + ㅔ + ㅇ + ㅛ', '주세요', '물 주세요', 'Please give me water', 'Mujhe paani dein'],
  ['ㅇ + ㅏ + ㄴ + ㄴ + ㅕ + ㅇ', '안녕', '안녕하세요', 'Hello', 'Salaam / Hello'],
];

/// Vocabulary: [korean, romanisation, english, roman-urdu]
const List<List<String>> vocab = [
  ['안녕하세요','annyeonghaseyo','Hello','Salaam'],
  ['감사합니다','gamsahamnida','Thank you','Shukriya'],
  ['네','ne','Yes','Ji haan'],
  ['아니요','aniyo','No','Nahi'],
  ['물','mul','Water','Paani'],
  ['밥','bap','Rice / meal','Chawal / khana'],
  ['집','jip','House','Ghar'],
  ['학교','hakgyo','School','School'],
  ['회사','hoesa','Company','Company'],
  ['나라','nara','Country','Mulk'],
  ['사람','saram','Person','Aadmi'],
  ['친구','chingu','Friend','Dost'],
  ['가족','gajok','Family','Khandan'],
  ['아버지','abeoji','Father','Walid'],
  ['어머니','eomeoni','Mother','Walida'],
  ['형','hyeong','Older brother','Bara bhai'],
  ['누나','nuna','Older sister','Bari behen'],
  ['돈','don','Money','Paisa'],
  ['시간','sigan','Time','Waqt'],
  ['오늘','oneul','Today','Aaj'],
  ['내일','naeil','Tomorrow','Kal'],
  ['어제','eoje','Yesterday','Kal (guzra)'],
  ['월요일','woryoil','Monday','Peer'],
  ['화요일','hwayoil','Tuesday','Mangal'],
  ['수요일','suyoil','Wednesday','Budh'],
  ['목요일','mogyoil','Thursday','Jumeraat'],
  ['금요일','geumyoil','Friday','Jumma'],
  ['토요일','toyoil','Saturday','Hafta'],
  ['일요일','iryoil','Sunday','Itwaar'],
  ['봄','bom','Spring','Bahaar'],
  ['여름','yeoreum','Summer','Garmi'],
  ['가을','gaeul','Autumn','Khizan'],
  ['겨울','gyeoul','Winter','Sardi'],
  ['비','bi','Rain','Baarish'],
  ['눈','nun','Snow','Barf'],
  ['병원','byeongwon','Hospital','Hospital'],
  ['약국','yakguk','Pharmacy','Dawai ki dukaan'],
  ['은행','eunhaeng','Bank','Bank'],
  ['우체국','ucheguk','Post office','Dak khana'],
  ['시장','sijang','Market','Bazaar'],
  ['음식','eumsik','Food','Khana'],
  ['빵','ppang','Bread','Roti / bread'],
  ['고기','gogi','Meat','Gosht'],
  ['과일','gwail','Fruit','Phal'],
  ['사과','sagwa','Apple','Seb'],
  ['우유','uyu','Milk','Doodh'],
  ['커피','keopi','Coffee','Coffee'],
  ['차','cha','Tea','Chai'],
  ['일','il','Work','Kaam'],
  ['공장','gongjang','Factory','Factory'],
  ['농장','nongjang','Farm','Khet / farm'],
  ['기계','gye','Machine','Machine'],
  ['안전','anjeon','Safety','Hifazat'],
  ['모자','moja','Helmet','Helmet'],
  ['장갑','janggap','Gloves','Dastane'],
  ['신발','sinbal','Shoes','Joota'],
  ['옷','ot','Clothes','Kapray'],
  ['전화','jeonhwa','Phone','Phone'],
  ['버스','beoseu','Bus','Bus'],
  ['지하철','jihacheol','Subway','Metro'],
  ['기차','gicha','Train','Train'],
  ['길','gil','Road','Rasta'],
  ['왼쪽','oenjjok','Left','Bayein'],
  ['오른쪽','oreunjjok','Right','Dayein'],
  ['앞','ap','Front','Aage'],
  ['뒤','dwi','Back','Peeche'],
  ['크다','keuda','Big','Bara'],
  ['작다','jakda','Small','Chhota'],
  ['좋다','jota','Good','Achha'],
  ['나쁘다','nappeuda','Bad','Bura'],
  ['춥다','chupda','Cold','Thanda'],
  ['덥다','deopda','Hot','Garam'],
  ['먹다','meokda','To eat','Khana'],
  ['마시다','masida','To drink','Peena'],
  ['가다','gada','To go','Jaana'],
  ['오다','oda','To come','Aana'],
  ['보다','boda','To see','Dekhna'],
  ['듣다','deutda','To listen','Sunna'],
  ['말하다','malhada','To speak','Bolna'],
  ['공부하다','gongbuhada','To study','Parhna'],
  ['일하다','ilhada','To work','Kaam karna'],
  ['자다','jada','To sleep','Sona'],
  ['일어나다','ireonada','To wake up','Uthna'],
  ['사다','sada','To buy','Kharidna'],
  ['팔다','palda','To sell','Bechna'],
  ['도와주세요','dowajuseyo','Please help me','Meri madad karein'],
  ['다쳤어요','dachyeosseoyo','I am hurt','Mujhe chot lagi hai'],
  ['배가 고파요','baega gopayo','I am hungry','Mujhe bhookh lagi hai'],
  ['목이 말라요','mogi mallayo','I am thirsty','Mujhe pyaas lagi hai'],
  ['화장실이 어디예요?','hwajangsiri eodiyeyo?','Where is the toilet?','Toilet kahan hai?'],
  ['이해가 안 돼요','ihaega an dwaeyo','I do not understand','Mujhe samajh nahi aaya'],
  ['천천히 말해 주세요','cheoncheonhi malhae juseyo','Please speak slowly','Aahista bolein'],
  ['얼마예요?','eolmayeyo?','How much is it?','Kitne ka hai?'],
  ['감사합니다','gamsahamnida','Thank you','Shukriya'],
  ['죄송합니다','joesonghamnida','Sorry','Maaf karein'],
  ['잘 지내요?','jal jinaeyo?','How are you?','Aap kaise hain?'],
  ['이름이 뭐예요?','ireumi mwoyeyo?','What is your name?','Aap ka naam kya hai?'],
  ['저는 파키스탄 사람이에요','jeoneun pakiseutan saramieyo','I am from Pakistan','Main Pakistan se hoon'],
  ['한국말을 조금 해요','hangungmareul jogeum haeyo','I speak a little Korean','Main thoda Korean bolta hoon'],
];

/// Emergency phrases: [korean, romanisation, english, roman-urdu]
const List<List<String>> emergency = [
  ['다쳤어요','dachyeosseoyo','I am hurt','Mujhe chot lagi hai'],
  ['도와주세요','dowajuseyo','Please help me','Meri madad karein'],
  ['화장실이 어디예요?','hwajangsiri eodiyeyo?','Where is the toilet?','Toilet kahan hai?'],
  ['이해가 안 돼요','ihaega an dwaeyo','I do not understand','Mujhe samajh nahi aaya'],
  ['월급이 늦었어요','wolgeubi neujeosseoyo','My salary is late','Meri tankhwah late hai'],
  ['아파요','apayo','I am sick / it hurts','Mujhe dard hai / main beemar hoon'],
  ['위험해요!','wiheomhaeyo!','Danger!','Khatra hai!'],
  ['불이 났어요!','buri nasseoyo!','There is a fire!','Aag lag gayi hai!'],
  ['119에 전화해 주세요','ililgu-e jeonhwahae juseyo','Please call 119','119 par call karein'],
  ['병원에 가고 싶어요','byeongwone gago sipeoyo','I want to go to hospital','Main hospital jaana chahta hoon'],
];

/// Skill Test tasks (Round 2): [name, steps]
const List<List<String>> skillTasks = [
  ['Pin insertion','Put the pin in the hole, straight, no force. Check it sits flat.'],
  ['Joint connection','Join the two parts, line up the marks, tighten by hand first.'],
  ['Measuring and cutting','Measure twice, mark clearly, cut slowly on the line.'],
  ['Pipe bolting','Put the bolt through, washer on, tighten evenly, do not over-tighten.'],
  ['Grinder','Wear goggles and gloves, hold with both hands, sparks away from you.'],
  ['Packaging','Fold the box, tape the base, pack neatly, label the outside.'],
  ['Pallet loading','Stack heavy boxes at the bottom, light on top, wrap it tight.'],
];

/// Tutor starter Q&A in 6 languages: [lang, question, korean, romanisation, meaning-in-that-lang]
const List<List<String>> tutorStarters = [
  ['English','How do I say I am hungry in Korean?','배가 고파요','baega gopayo','I am hungry'],
  ['Urdu','Korean mein bhookh lagi hai kaise kehte hain?','배가 고파요','baega gopayo','Mujhe bhookh lagi hai'],
  ['Punjabi','Mainu bhookh lagi hai, Korean vich ki kehnde ne?','배가 고파요','baega gopayo','Mainu bhookh lagi hai'],
  ['Pashto','Za wagi yam, pa Korean ke sanga way?','배가 고파요','baega gopayo','Za wagi yam'],
  ['Sindhi','Moon khi bukh lagi aahy, Korean mein chha chawanda aahin?','배가 고파요','baega gopayo','Moon khi bukh lagi aahy'],
  ['Saraiki','Mainu bhuk lagi ae, Korean ich kivein aakhde ne?','배가 고파요','baega gopayo','Mainu bhuk lagi ae'],
];

const List<String> tutorLanguages = ['English','Urdu','Punjabi','Pashto','Sindhi','Saraiki'];

const List<String> slogansCorrect = [
  'Wah bhai wah, Korea pakka!',
  'Tu to gaya Korea!',
  'Seoul, here you come!',
  'Boss level clear!',
  'Korea ki ticket pakki!',
];
const List<String> slogansWrong = [
  'Ghalat jawab, lekin himmat na haar, dobara kar!',
  'Korea nahi jana kya bhai, tayari kar le!',
  'Oye, phir se try kar, Korea door nahi!',
  'Arre bhai, book kholo, phir aao!',
];

/// 12-week self-study plan: [week, task]
const List<List<String>> selfStudyPlan = [
  ['Week 1','Hangul vowels, 30 minutes a day. Write each letter 5 times.'],
  ['Week 2','Hangul consonants + first syllables (가, 나, 다).'],
  ['Week 3','Greetings + self introduction (Unit 1). 20 new words.'],
  ['Week 4','Daily life words (Units 2–5). First listening practice.'],
  ['Week 5','Food, shopping, dates (Units 9–10, 5). First Speak Test.'],
  ['Week 6','Transport, directions, house (Units 12, 14, 16).'],
  ['Week 7','Hospital, pharmacy, bank (Units 21–24).'],
  ['Week 8','Workplace culture (Units 31–35). Safety signs (Unit 53).'],
  ['Week 9','Your sector job units: manufacturing 37–40 or agriculture 45–47.'],
  ['Week 10','Laws: EPS system, labour law, insurance (Units 57–60).'],
  ['Week 11','Full mock test, timed 50 minutes. Fix weak topics.'],
  ['Week 12','Second full mock + Skill Test practice. You are test-ready.'],
];

const List<String> docChecklist = [
  'Passport','CNIC','Medical certificate','Police character certificate',
  'Photos','Bank account','OEC forms','Roster form','Job application','Health declaration',
];

const List<String> cultureLessons = [
  'How to bow — a small bow to your boss and older colleagues, every morning.',
  'How to speak to a boss — polite endings (-요 / -습니다), never shout, never argue in public.',
  'How to eat with colleagues — wait for the oldest person to start, do not stick chopsticks upright in rice.',
  'At work — arrive 5 minutes early, wear safety gear always, ask if you do not understand.',
  'What not to do — do not point with one finger, do not touch a boss’s head, do not be late.',
];
