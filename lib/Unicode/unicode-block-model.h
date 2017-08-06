/* unicode-block-model.h
 *
 * Originally a part of Gucharmap
 *
 * Copyright © 2017 Jerry Casiano
 *
 *
 * Copyright © 2004 Noah Levitt
 * Copyright © 2007 Christian Persch
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02110-1301  USA
 */

#ifndef __UNICODE_BLOCK_MODEL_H__
#define __UNICODE_BLOCK_MODEL_H__

#include <glib.h>

#include "unicode-chapters-model.h"

G_BEGIN_DECLS

#define UNICODE_TYPE_BLOCK_MODEL (unicode_block_model_get_type())
G_DECLARE_FINAL_TYPE(UnicodeBlockModel, unicode_block_model, UNICODE, BLOCK_MODEL, GtkListStore)

UnicodeBlockModel * unicode_block_model_new (void);

G_END_DECLS

#endif /* #ifndef __UNICODE_BLOCK_MODEL_H_ */
