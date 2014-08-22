/* Constants.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    const string NAME = "font-manager";
    const string SCHEMA_ID = "org.gnome.FontManager";
    const string BUS_ID = SCHEMA_ID;
    const string BUS_PATH = "/org/gnome/FontManager";
    const string TMPL = "font-manager_XXXXXX";
    const string AUTHOR = "Jerry Casiano <JerryCasiano@gmail.com>";

    const string DEFAULT_COLLECTION_NAME = _("Enter Collection Name");
    const string DEFAULT_FONT = "Sans";

    const string DEFAULT_PREVIEW_TEXT = """
%s

ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
1234567890.:,;(*!?')

""";

    const double DEFAULT_PREVIEW_SIZE = 10;
    const double MIN_FONT_SIZE = 6.0;
    const double MAX_FONT_SIZE = 96.0;

    /* Most common font styles, we try to select one of these if possible */
    const string [] DEFAULT_VARIANTS = {
        "Regular",
        "Roman",
        "Medium",
        "Normal",
        "Book"
    };

    /* Standard Aliases, exclude these */
    const string [] DEFAULT_ALIASES = {
        "Monospace",
        "Sans",
        "Serif"
    };

    /* Words commonly found in font version strings, exclude these */
    const string [] VERSION_STRING_EXCLUDES = {
        "Version",
        "version",
        "Revision",
        "revision",
        ";FFEdit",
        "$Revision",
        "$:",
        "$"
    };

    const string [] FONT_METRICS = {
        ".afm",
        ".pfa",
        ".pfm"
    };

    const string [] FONT_MIMETYPES = {
        "application/x-font-ttf",
        "application/x-font-ttc",
        "application/x-font-otf",
        "application/x-font-type1"
    };

    /* Mimetypes that are likely to cause an error, unlikely to contain usable fonts.
     * i.e.
     * Windows .FON files are classified as "application/x-ms-dos-executable"
     * but file-roller is unlikely to extract one successfully.
     * */
    const string [] ARCHIVE_IGNORE_LIST = {
        "application/x-ms-dos-executable"
    };

    const string LOREM_IPSUM = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent sed tristique nunc. Sed augue dolor, posuere a auctor quis, dignissim sed est. Aliquam convallis, orci nec posuere lacinia, risus libero mattis velit, a consectetur orci felis venenatis neque. Praesent id lacinia massa. Nam risus diam, faucibus vitae pulvinar eget, scelerisque nec nisl. Integer dolor ligula, placerat id elementum id, venenatis sed massa. Vestibulum at convallis libero. Curabitur at molestie justo.

Mauris convallis odio rutrum elit aliquet quis fermentum velit tempus. Ut porttitor lectus at dui iaculis in vestibulum eros tristique. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec ut dui massa, at aliquet leo. Cras sagittis pulvinar nunc. Fusce eget felis ut dolor blandit scelerisque non eget risus. Nunc elementum ipsum id lacus porttitor accumsan. Suspendisse at quam ligula, ultrices bibendum massa.

Mauris feugiat, orci non fermentum congue, libero est rutrum sem, non dignissim justo urna at turpis. Donec non varius augue. Fusce id enim ligula, sit amet mattis urna. Ut sodales augue tristique tortor lobortis vestibulum. Maecenas quis tortor lacus. Etiam varius hendrerit bibendum. Nullam pretium nulla in sem blandit vel facilisis felis fermentum. Integer aliquet leo nec nunc sollicitudin congue. In hac habitasse platea dictumst. Curabitur mattis nibh ac velit euismod condimentum. Pellentesque volutpat, neque ac congue fermentum, turpis metus posuere turpis, ac facilisis velit lectus sed diam. Etiam dui diam, tempus vitae fringilla quis, tincidunt ac libero.

Quisque sollicitudin eros sit amet lorem semper nec imperdiet ante vehicula. Proin a vulputate sem. Aliquam erat volutpat. Vestibulum congue pulvinar eros eu vestibulum. Phasellus metus mauris, suscipit tristique ullamcorper laoreet, viverra eget libero. Donec id nibh justo. Aliquam sagittis ultricies erat. Integer sed purus felis. Pellentesque leo nisi, sagittis non tincidunt vitae, porta quis eros. Pellentesque ut ornare erat. Vivamus semper sodales suscipit. Praesent placerat eleifend nibh quis tristique. Aenean ullamcorper pellentesque ultrices. Nunc eu risus turpis, in condimentum dui. Aliquam erat volutpat. Phasellus sagittis mattis diam, sit amet pharetra lacus cursus non.

Vestibulum sed est id velit rhoncus imperdiet. Aliquam dictum, arcu at tincidunt condimentum, metus ligula molestie lorem, eget congue tortor est ut massa. Duis ut pulvinar nisl. Aenean sodales purus id risus hendrerit sit amet mattis sem blandit. Aenean feugiat dapibus mattis. Praesent non nibh magna. Nulla facilisi. Nam elementum malesuada sagittis. Cras et tellus augue, non rhoncus libero. Suspendisse ut nulla mauris.

Suspendisse potenti. Nulla neque leo, condimentum nec posuere non, elementum sit amet lorem. Integer ut ante libero, a tristique quam. Nulla libero nibh, bibendum eget blandit non, viverra in velit. Duis sit amet ipsum in massa imperdiet interdum. Phasellus venenatis consequat lectus eget facilisis. Quisque ullamcorper rutrum erat at egestas. Integer pharetra pulvinar odio, sagittis imperdiet ligula aliquam suscipit. Aenean rutrum convallis felis, at rhoncus lectus tincidunt et. Morbi mattis risus eu quam suscipit ut tempus nunc pellentesque. Ut adipiscing, nibh nec pharetra fringilla, diam diam hendrerit neque, quis pretium tellus ligula ut dolor. Nullam dictum, libero in molestie convallis, nunc arcu imperdiet risus, vitae laoreet risus ipsum in ligula. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec molestie, quam ut adipiscing consequat, risus sem facilisis nisi, ut aliquet sapien est a sapien. Quisque sed enim justo, sit amet volutpat urna.

Integer faucibus, velit sit amet aliquam fermentum, turpis massa facilisis nunc, eu vulputate lorem sapien at sapien. Quisque sed lacus non massa varius fermentum. Fusce non consectetur odio. Integer tincidunt tincidunt ullamcorper. In hac habitasse platea dictumst. Donec tellus est, feugiat in auctor sed, sodales non urna. Curabitur semper cursus eros, id hendrerit tortor pulvinar at. Mauris gravida odio vel lorem mattis varius. Donec vulputate aliquam dui et dignissim. Pellentesque consectetur nisi sit amet libero consectetur quis imperdiet libero tristique. Praesent nec enim ante. Proin quam mauris, vehicula vel lobortis at, tempor vitae augue. Sed ut urna vel eros facilisis mollis vulputate at nisl. Integer lobortis magna vitae urna varius tristique. In hac habitasse platea dictumst.

Sed ac molestie ante. Fusce ultrices laoreet felis ac lobortis. Curabitur a vulputate risus. Suspendisse auctor pulvinar semper. Mauris nec ipsum vitae justo malesuada tincidunt. In suscipit porttitor nibh, at convallis justo ultrices ac. Sed vitae turpis vel quam malesuada gravida a non ante.

Suspendisse sit amet felis sit amet nisl lacinia ultrices ut vitae tellus. In hac habitasse platea dictumst. In hac habitasse platea dictumst. Sed interdum porta dui, in placerat arcu porttitor vel. Nullam justo velit, blandit ut accumsan id, ullamcorper sed lacus. Nullam scelerisque tellus vitae nisi placerat sollicitudin. Integer massa erat, facilisis sed porta eu, porttitor at leo. Praesent mauris mi, tincidunt id cursus et, consequat sit amet arcu. Sed posuere erat nec nunc hendrerit id semper quam facilisis. Curabitur pretium placerat neque at sodales.

Etiam augue eros, dictum eu adipiscing in, aliquam quis dui. Pellentesque auctor sem mattis magna faucibus vulputate. Nam arcu purus, eleifend eget sagittis ac, posuere a lorem. Aenean urna magna, viverra quis commodo vitae, gravida eget arcu. Maecenas ut turpis magna, mattis gravida risus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec eu libero sem. Donec eget nibh id turpis convallis tincidunt. Fusce vulputate tempor tempor.

Nunc eleifend metus in augue rhoncus sodales. Nam vel enim at neque tristique accumsan. Nunc ac venenatis massa. Morbi gravida facilisis odio sit amet venenatis. Maecenas sodales euismod nisi eu bibendum. Duis tempor pulvinar diam, nec mollis risus viverra quis. Nullam ipsum mauris, fringilla eget vulputate a, euismod ac urna. Nam eu eros sapien. Phasellus et eros lorem. Quisque varius porta pharetra. Donec vel libero euismod arcu pharetra tincidunt. Sed sit amet neque erat. Mauris dictum nisi quis risus tincidunt pellentesque. Maecenas accumsan elit rhoncus tortor elementum pretium. Donec dictum convallis lectus in fermentum. Mauris accumsan, turpis ac consectetur varius, lacus metus sagittis neque, in tincidunt dui enim id diam.

Aenean lacinia eros nec enim cursus at porttitor quam suscipit. Nam quam turpis, iaculis et congue non, dignissim nec neque. Mauris nec erat erat, vitae ornare velit. Aenean suscipit, eros eu cursus imperdiet, felis lacus lobortis metus, ac laoreet tellus nunc id arcu. Etiam libero mi, pellentesque in feugiat nec, tincidunt in sapien. Fusce eu mi sed libero ullamcorper congue. Suspendisse eu sem sed arcu pulvinar vestibulum vel in lorem. Phasellus aliquam elementum iaculis. Etiam dictum luctus nisi sit amet mattis. Mauris mollis placerat varius.

Cras ultricies elit eget lectus sagittis sit amet rutrum enim tempus. Vivamus a risus pharetra nibh dapibus volutpat vitae sed arcu. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Quisque a augue nibh, nec congue metus. Integer elementum, purus sit amet vehicula gravida, mi magna hendrerit turpis, at aliquam purus velit eget tortor. Integer suscipit posuere massa, quis cursus massa tincidunt id. Integer placerat quam quis massa dapibus egestas at eu lorem. Aenean quis nunc sed massa lobortis tincidunt. Phasellus quis sem dolor. Phasellus auctor ipsum at ligula euismod eu sagittis justo dapibus. Pellentesque pulvinar, magna eget interdum eleifend, urna lectus adipiscing dui, eu cursus nulla tellus in lacus. Vivamus quis urna magna, a placerat est. Nullam justo tellus, elementum at viverra at, posuere quis magna.

Sed non est sed nibh blandit tincidunt. Fusce nec sem a mi mollis condimentum. Nulla ut lacinia tellus. Vestibulum iaculis fermentum risus, vel lobortis lorem posuere quis. Donec consequat ligula et arcu faucibus sed tempor sem ullamcorper. Curabitur sapien odio, egestas non congue id, dapibus non nisl. Nam euismod, massa eu laoreet tincidunt, velit mi pharetra dolor, laoreet suscipit quam erat vel felis. Praesent vulputate ipsum et elit scelerisque rhoncus. Nam ligula magna, gravida ac varius at, facilisis vitae ipsum. Praesent eleifend eleifend massa, tincidunt pharetra felis tincidunt nec. Etiam eu sapien lorem. Donec euismod faucibus erat a semper. Duis pharetra nulla at libero sollicitudin sed vestibulum diam egestas. Nam dignissim quam et massa placerat ac tincidunt nulla dapibus. Curabitur mi mi, sagittis id pharetra sed, semper eu ligula. Phasellus eu venenatis elit.

Ut mi libero, pharetra in vestibulum et, blandit ac purus. Donec sit amet scelerisque massa. Morbi commodo nisi non mi rhoncus vel pharetra lorem rutrum. Nulla eget arcu augue. Nunc ullamcorper, sapien ut imperdiet imperdiet, lorem mauris commodo justo, sit amet sodales nisl sem id turpis. Sed interdum sem dictum neque ullamcorper varius. Nulla elementum pharetra scelerisque. Fusce ut augue non mauris suscipit consectetur id vel justo. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Phasellus metus nulla, tempus facilisis pharetra ut, aliquam a arcu.

Morbi porttitor posuere rutrum. Nulla facilisi. Nam risus lorem, varius at fermentum id, euismod eget tellus. Quisque ut interdum leo. Etiam eget neque urna, vitae iaculis ante. Curabitur semper nisl vel orci hendrerit accumsan. Phasellus vel mi ac tellus rhoncus viverra sit amet lobortis mauris. Vestibulum pharetra tristique enim, a mattis dolor consequat quis. Aenean auctor, mi quis rhoncus iaculis, urna ante condimentum ligula, ac feugiat ipsum diam sit amet libero. Donec ac sapien ut quam ultrices pellentesque. Aenean venenatis ornare enim sed congue. Integer nec est massa. Pellentesque tincidunt justo at magna dictum blandit. Maecenas ipsum velit, condimentum ut pharetra quis, aliquet consequat tellus.

Mauris faucibus augue ut massa faucibus id hendrerit justo rutrum. Donec accumsan odio vel turpis dignissim mattis. Suspendisse magna eros, tempus vel commodo eu, aliquet sed libero. Ut fermentum dui quis lorem scelerisque lobortis. Aliquam volutpat odio id velit malesuada condimentum. Nulla facilisi. Donec sed nisi eget risus adipiscing rutrum. Duis egestas scelerisque eleifend. Mauris neque ligula, ullamcorper sed tincidunt aliquet, facilisis non dolor. Mauris eget elit leo. Donec suscipit, felis sed auctor tincidunt, arcu velit posuere elit, malesuada molestie libero quam nec mauris.

Morbi non nunc faucibus sem rutrum aliquam eget nec nisi. Donec iaculis, arcu at elementum sollicitudin, libero enim dictum tellus, et pellentesque turpis erat aliquet dolor. Etiam et magna in nisi pharetra consectetur. Phasellus accumsan volutpat nibh non dictum. Pellentesque pretium tellus id neque ultricies iaculis. Ut a libero eget dolor porttitor hendrerit. Integer eleifend elit quis turpis lacinia vitae scelerisque leo gravida.

Curabitur tempor eros vitae velit ultrices ornare. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Mauris tristique erat ac arcu gravida non dictum magna aliquam. Phasellus eu velit quis est ullamcorper pharetra. Aenean vestibulum gravida urna, vitae posuere libero dapibus ac. Etiam a massa eget felis tincidunt pellentesque. Nulla facilisi. Nullam odio dui, commodo eu vulputate quis, feugiat in ipsum. Sed sed viverra sapien.

Mauris consectetur neque ut mauris feugiat et rhoncus purus gravida. Nam nibh sem, iaculis at lacinia vitae, faucibus lobortis mauris. Maecenas ornare urna sit amet eros blandit pulvinar. Suspendisse nisi massa, ornare vitae vestibulum eget, dictum nec leo. Phasellus et risus risus. Suspendisse potenti. Donec imperdiet eleifend dui tincidunt sodales.

Morbi ac erat nisi. Maecenas mi ante, rutrum at rhoncus viverra, facilisis quis turpis. Ut in lacus diam, ac euismod quam. Etiam auctor ultricies consectetur. Vivamus semper, sem nec posuere eleifend, tortor lorem sagittis urna, eu iaculis tortor leo et ligula. Nam vitae libero tellus, vitae rutrum nulla. Phasellus suscipit massa eget mauris pharetra adipiscing. Donec mattis sem in leo sollicitudin vitae tempus lorem tincidunt. Fusce sagittis metus sit amet ante scelerisque ut vulputate felis venenatis. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla dictum arcu eget metus sagittis faucibus. Nulla eget mauris a tellus ornare dictum ac eu massa. Vestibulum dapibus, turpis non adipiscing convallis, nisi turpis pharetra elit, ac tincidunt sem dui sit amet lacus. Pellentesque ac mi lacus, volutpat cursus leo. Ut ac sollicitudin nibh.

Phasellus et porta risus. Ut a neque quam. Aliquam euismod diam vitae felis sodales pellentesque non sit amet ipsum. In lorem arcu, posuere at elementum at, malesuada in mauris. In viverra adipiscing adipiscing. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Sed ut lacus purus, non egestas quam. Curabitur convallis, ipsum quis egestas varius, odio tellus accumsan ipsum, et interdum eros felis posuere lorem. Fusce congue viverra quam, sed ullamcorper orci euismod non. Vestibulum semper turpis eu turpis mollis eget aliquam turpis dapibus. Praesent volutpat justo eget ligula facilisis non fermentum lorem consequat. Phasellus ac diam erat. Phasellus nisi leo, aliquet posuere facilisis eu, mattis non tellus. Pellentesque eros metus, pretium venenatis pharetra vel, ullamcorper ac est. Sed massa ante, fermentum in tincidunt ac, eleifend eget turpis.

Nullam commodo dui at quam pulvinar a luctus sapien pretium. In hendrerit pretium consectetur. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nam aliquet erat vel lorem feugiat tincidunt. Ut eget magna lectus. Aliquam augue eros, gravida vel commodo vel, interdum sit amet sapien. Sed nec turpis enim, a faucibus orci. Nullam non lectus risus, vitae laoreet metus. Praesent in erat dui. Ut ac laoreet nibh. Sed tortor eros, ultrices eu dapibus et, tristique in quam. Vivamus id lacinia lacus. Sed et elit mi. Nullam erat purus, posuere at mollis in, tempor ut risus. Vivamus sollicitudin scelerisque vehicula.

Morbi nec volutpat nulla. Sed venenatis ligula nec magna luctus sagittis. Ut faucibus diam in lorem vulputate id porta turpis venenatis. Duis tempus cursus erat, sit amet sollicitudin erat faucibus sit amet. Donec facilisis, orci eget ultricies semper, elit ante euismod purus, at pretium turpis metus ac sapien. Pellentesque quis sem eget ante congue gravida at sit amet erat. Nam condimentum arcu ut urna scelerisque et fermentum mauris sagittis. In mauris lectus, accumsan eu malesuada eu, congue at nulla. Nulla dui elit, sodales non fermentum eget, iaculis vitae est. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi arcu eros, ultricies a hendrerit a, faucibus in nibh. Vestibulum diam sapien, facilisis et placerat a, sodales ut leo. In luctus ligula quis purus scelerisque varius ac id eros. Mauris consequat pulvinar diam at commodo.

Vestibulum lobortis viverra quam, quis posuere est tincidunt nec. Vestibulum ac elit non ligula faucibus pretium laoreet vel erat. Fusce sodales, erat et condimentum luctus, justo lorem gravida tortor, eget consequat orci risus ac metus. Sed pulvinar pretium felis et porta. Aliquam erat volutpat. Integer pellentesque aliquam odio eu facilisis. Aenean ultrices felis eget risus tempus pulvinar. Pellentesque eros mi, gravida vel condimentum nec, ornare ac neque. Phasellus risus ligula, vehicula non varius non, tincidunt at arcu. Quisque at quam a lorem aliquet tempus vel non sapien.
""";

    const string CREATE_SQL = """CREATE TABLE IF NOT EXISTS Fonts
(
uid INTEGER PRIMARY KEY,
family TEXT,
style TEXT,
slant INTEGER,
weight INTEGER,
width INTEGER,
spacing INTEGER,
findex INTEGER,
filepath TEXT,
owner INTEGER,
filetype TEXT,
filesize TEXT,
checksum TEXT,
version TEXT,
psname TEXT,
description TEXT,
vendor TEXT,
copyright TEXT,
license_type TEXT,
license_data TEXT,
license_url TEXT,
panose TEXT,
font_description TEXT
);
""";

}


