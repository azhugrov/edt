// Copyright (c) 2012, the EDT project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** This is a base class for a compiled templates in dart */
abstract class EDTemplate {
  /** Renders a given template */
  abstract String render(Map data, OutputStream out);
  
  /** Utility function used to escape html */
  String escapeHtml(Object obj) {
    return obj.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('>', '&gt;')
        .replaceAll('<', '&lt;')
        .replaceAll('"', '&quot;');
  }   
}