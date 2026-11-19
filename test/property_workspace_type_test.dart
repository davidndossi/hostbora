import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/local/db/property_local_data_source.dart';

void main() {
  test('property workspace comes from workspace_type, not unit mode', () {
    expect(
      PropertyRecord.workspaceFromApiMap({
        'workspace_type': 'rent',
        'operationMode': 'bnb',
        'listingMode': 'bnb',
      }),
      'rent',
    );
    expect(
      PropertyRecord.workspaceFromApiMap({
        'workspaceType': 'rent',
        'operationMode': 'bnb',
      }),
      'rent',
    );
    expect(
      PropertyRecord.workspaceFromApiMap({
        'operationMode': 'bnb',
        'listingMode': 'bnb',
      }),
      isNull,
    );
  });

  test('property API helpers read SQL columns only', () {
    const map = {
      'name': 'AB Apartment',
      'title': 'Ignored title',
      'propertyName': 'Ignored propertyName',
      'location': 'Kizota, Changanyikeni',
      'address': 'Ignored address',
      'property_ref': 'local_1793446069087',
      'listingId': 'ignored-listing',
      'id': 1,
      'cover_photo_path': 'images/LR-13.jpg',
      'coverPhotoUrl': 'https://ignored.example/photo.jpg',
      'units_json': '[{"unitId":"u_1","operationMode":"rent"}]',
    };

    expect(PropertyRecord.remoteName(map), 'AB Apartment');
    expect(PropertyRecord.remoteLocation(map), 'Kizota, Changanyikeni');
    expect(PropertyRecord.remoteRef(map), 'local_1793446069087');
    expect(PropertyRecord.remoteCoverPhoto(map), 'images/LR-13.jpg');
    expect(
      PropertyRecord.remoteUnitsJson(map),
      '[{"unitId":"u_1","operationMode":"rent"}]',
    );
  });
}
