/* extension-common.h
 *
 * Copyright (C) 2022-2024 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.
 *
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
*/

#pragma once

#define FONT_VIEWER_BUS_ID "org.gnome.FontViewer"
#define FONT_VIEWER_BUS_PATH "/com/github/FontManager/FontManagerViewer"

#define N_MIMETYPES 7

static const char *MIMETYPES [N_MIMETYPES] = {
    "font/ttf",
    "font/ttc",
    "font/otf",
    "font/collection",
    "application/x-font-ttf",
    "application/x-font-ttc",
    "application/x-font-otf",
};

