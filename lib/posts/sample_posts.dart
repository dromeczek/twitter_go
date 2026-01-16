import 'package:twitter_go/posts/post.dart';

const List<Post> samplePosts = <Post>[
  Post(
    id: 'p1',
    title: 'Rynek – sekret',
    content: 'Jeśli to czytasz, to znaczy że dotarłeś na Rynek Główny 😄',
    lat: 50.06465,
    lng: 19.94498,
    unlockRadiusMeters: 80,
  ),
  Post(
    id: 'p2',
    title: 'Wawel – wskazówka',
    content: 'Wawel zaliczony. Następny punkt: Kazimierz.',
    lat: 50.05490,
    lng: 19.93520,
    unlockRadiusMeters: 80,
  ),
  Post(
    id: 'p3',
    title: 'Kazimierz – finał',
    content: 'Brawo! Ukończyłeś trasę demo 🚶📍',
    lat: 50.05170,
    lng: 19.94500,
    unlockRadiusMeters: 80,
  ),
];
