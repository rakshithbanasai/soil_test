import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Utils/app_strings.dart';

class MultipleImageSelector extends StatefulWidget {
  const MultipleImageSelector({super.key});

  @override
  State<MultipleImageSelector> createState() => MultipleImageSelectorState();
}

class MultipleImageSelectorState extends State<MultipleImageSelector> {
  List<File> selectedImages = [];
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    getImages();
    return Expanded(
      child: SizedBox(
        width: 250,
        height: 250,
        child: selectedImages.isEmpty
            ? const Center(child: Text(app_strings.noImageSelected))
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                itemBuilder: (BuildContext context, int index) {
                  return Center(
                    child: kIsWeb
                        ? Image.network(
                            selectedImages[index].path,
                            fit: BoxFit.fill,
                            width: 250,
                            height: 250,
                            alignment: Alignment.center,
                          )
                        : Image.file(
                            selectedImages[index],
                            fit: BoxFit.fill,
                            width: 250,
                            height: 250,
                            alignment: Alignment.center,
                          ),
                  );
                }, separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 10);
        },
              ),
        // GridView.builder(
        //         itemCount: selectedImages.length,
        //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //           crossAxisCount: 2,
        //         ),
        //         itemBuilder: (BuildContext context, int index) {
        //           return Center(
        //             child: kIsWeb
        //                 ? Image.network(
        //                     selectedImages[index].path,
        //                     fit: BoxFit.fill,
        //                     alignment: Alignment.center,
        //                   )
        //                 : Image.file(
        //                     selectedImages[index],
        //                     fit: BoxFit.fill,
        //                     alignment: Alignment.center,
        //                   ),
        //           );
        //         },
        //       ),
      ),
    );
  }

  Future getImages() async {
    final pickedFile = await picker.pickMultiImage(
      requestFullMetadata: true,
      imageQuality: 100,
      maxHeight: 1000,
      maxWidth: 1000,
    );
    List<XFile> xFilePick = pickedFile;

    setState(() {
      if (xFilePick!.isNotEmpty) {
        for (var i = 0; i < xFilePick.length; i++) {
          selectedImages.add(File(xFilePick[i].path));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nothing is selected')));
      }
    });
  }
}
