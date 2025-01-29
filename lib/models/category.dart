
import 'package:uuid/uuid.dart';

const uuid = Uuid();
class Category {

Category({
   required this.name,
   required this.imageUrl,
}): id = uuid.v4();

final String id;
final String name;
final String imageUrl;

}