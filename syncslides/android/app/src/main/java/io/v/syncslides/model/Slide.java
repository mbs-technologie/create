// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.syncslides.model;

import android.graphics.Bitmap;

/**
 * A slide.
 */
public interface Slide {
    /**
     * Returns the unique id for this slide.
     */
    String getId();

    /**
     * Returns a Bitmap of the slide thumbnail.
     */
    Bitmap getThumb();

    /**
     * Returns the raw thumbnail data.
     */
    byte[] getThumbData();

    /**
     * Returns a Bitmap of the slide image.
     */
    Bitmap getImage();

    /**
     * Returns the raw image data.
     */
    byte[] getImageData();

    /**
     * Returns the slide notes.
     */
    String getNotes();
}
