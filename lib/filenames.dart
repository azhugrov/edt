// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('filenames');
#import('dart:io');

final RegExp SplitDeviceReWin = const RegExp(@"^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/][^\\\/]+)?([\\\/])?([\s\S]*?)$");
final RegExp SplitTailReWin = const RegExp(@"^([\s\S]+[\\\/](?!$)|[\\\/])?((?:[\s\S]+?)?(\.[^.]*)?)$");
final RegExp SplitPathRePosix = const RegExp(@"^(\/?)([\s\S]+\/(?!$)|\/)?((?:[\s\S]+?)?(\.[^.]*)?)$");

/** 
 * resolves . and .. elements in a path array with directory names there
 * must be no slashes, empty elements, or device names (c:\) in the array
 * (so also no leading and trailing slashes - it does not distinguish
 * relative and absolute paths)
 */
List<String> _normalizeArray(List<String> parts, bool allowAboveRoot) {
  printArray(parts);
  
  // if the path tries to go above the root, `up` ends up > 0
  int up = 0;
  for (var i = parts.length - 1; i >= 0; i--) {
    var last = parts[i];
    if (last == '.') {
      parts.removeRange(i, 1);
    } 
    else if (last == '..') {
      parts.removeRange(i, 1);
      up++;
    } 
    else if (up > 0) {
      parts.removeRange(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up-- > 0; up) {
      parts.insertRange(0, 1, "..");
    }
  }

  return parts;
}

void printArray(List<String> array) {
  for (String item in array) {
    print("Split item: $item");    
  }  
}

String pathNormalize(String path) {
  /** Whenever underlying platform is windows */
  bool isWindows = Platform.operatingSystem == 'windows';
  if (isWindows) {
    Match result = SplitDeviceReWin.firstMatch(path);
    String device = result.group(1);
    bool isUnc = device !== null && device.substring(1, 2) != ":";
    bool isAbsolute = result.group(2) != null || isUnc; // UNC paths are always absolute
    String tail = result.group(3);
    bool trailingSlash = const RegExp(@"[\\/]$").hasMatch(tail);
    print("trailingSlash: $trailingSlash");
    List<String> pathParts = tail.split(const RegExp(@"[\\/]+")).filter((part) {
      return part != "";
    });
    // Normalize the tail path
    tail = Strings.join(_normalizeArray(pathParts, !isAbsolute), @"\");
  
    if (tail === null && !isAbsolute) {
      tail = '.';
    }
    if (tail !== null && trailingSlash) {
      tail = "$tail\\";
    }
    
    var buf = new StringBuffer();
    buf.add(device);
    if (isAbsolute) {
      buf.add(@"\");      
    } 
    buf.add(tail);
    return buf.toString();
  } else {
    //NOTE(zhuhrou) please implement this for other platform
    //the sources could be found in node.js implementation
    throw new Exception("not implemented yet");
  }
}

String pathJoin(List<String> paths) {
  
}

String getCurrentDirectory() {
  return new File('.').fullPathSync();
}

String appendSlash(String path) => path.endsWith('/') ? path : '$path/';