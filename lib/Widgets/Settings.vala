
namespace Granite {
    [DBus (name = "io.elementary.pantheon.AccountsService")]
    private interface Pantheon.AccountsService : Object {
        public abstract int prefers_accent_color { owned get; set; }
        public abstract int prefers_color_scheme { owned get; set; }
    }

    [DBus (name = "org.freedesktop.Accounts")]
    interface FDO.Accounts : Object {
        public abstract string find_user_by_name (string username) throws GLib.Error;
    }

    /**
     * Granite.Settings provides a way to share Pantheon desktop settings with applications.
     */
    public class Settings : Object {
        /**
         * Possible accent color preferences expressed by the user
         */
         public enum AccentColor {
            /**
             * The user has not expressed a accent color preference.
             */
            NO_PREFERENCE,
            /**
             * The user prefers red as accent color.
             */
            RED,
            /**
             * The user prefers orange as accent color.
             */
            ORANGE,
            /**
             * The user prefers yellow as accent color.
             */
            YELLOW,
            /**
             * The user prefers green as accent color.
             */
            GREEN,
            /**
             * The user prefers mint as accent color.
             */
            MINT,
            /**
             * The user prefers blue as accent color.
             */
            BLUE,
            /**
             * The user prefers purple as accent color.
             */
            PURPLE,
            /**
             * The user prefers pink as accent color.
             */
            PINK,
            /**
             * The user prefers brown as accent color.
             */
            BROWN,
            /**
             * The user prefers gray as accent color.
             */
            GRAY
        }

        /**
         * Possible color scheme preferences expressed by the user
         */
        public enum ColorScheme {
            /**
             * The user has not expressed a color scheme preference. Apps should decide on a color scheme on their own.
             */
            NO_PREFERENCE,
            /**
             * The user prefers apps to use a dark color scheme.
             */
            DARK,
            /**
             * The user prefers a light color scheme.
             */
            LIGHT
        }

        private AccentColor? _prefers_accent_color = null;
        private ColorScheme? _prefers_color_scheme = null;

        /**
         * Accent color the user would prefer or if the user has expressed no preference.
         */
         public AccentColor prefers_accent_color {
            get {
                if (_prefers_accent_color == null) {
                    setup_prefers_accent_color ();
                }
                return _prefers_accent_color;
            }
            private set {
                _prefers_accent_color = value;
            }
        }

        /**
         * Whether the user would prefer if apps use a dark or light color scheme or if the user has expressed no preference.
         */
        public ColorScheme prefers_color_scheme {
            get {
                if (_prefers_color_scheme == null) {
                    setup_prefers_color_scheme ();
                }
                return _prefers_color_scheme;
            }
            private set {
                _prefers_color_scheme = value;
            }
        }

        private string? _user_path = null;
        private string user_path {
            get {
                if (_user_path == null) {
                    setup_user_path ();
                }
                return _user_path;
            }
            private set {
                _user_path = value;
            }
        }

        private static GLib.Once<Granite.Settings> instance;
        public static unowned Granite.Settings get_default () {
            return instance.once (() => {
                return new Granite.Settings ();
            });
        }

        private FDO.Accounts? accounts_service = null;
        private Pantheon.AccountsService? pantheon_act = null;

        private Settings () {}

        private void setup_user_path () {
            try {
                accounts_service = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                   "org.freedesktop.Accounts",
                   "/org/freedesktop/Accounts"
                );

                _user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());
            } catch (Error e) {
                critical (e.message);
            }
        }

        private void setup_prefers_accent_color () {
            try {
                pantheon_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    user_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );

                prefers_accent_color = (AccentColor) pantheon_act.prefers_accent_color;

                ((GLib.DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                    var accent_color = changed.lookup_value ("PrefersAccentColor", new VariantType ("i"));
                    if (accent_color != null) {
                        prefers_accent_color = (AccentColor) accent_color.get_int32 ();
                    }
                });
            } catch (Error e) {
                critical (e.message);
            }
        }

        private void setup_prefers_color_scheme () {
            try {
                pantheon_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    user_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );

                prefers_color_scheme = (ColorScheme) pantheon_act.prefers_color_scheme;

                ((GLib.DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                    var color_scheme = changed.lookup_value ("PrefersColorScheme", new VariantType ("i"));
                    if (color_scheme != null) {
                        prefers_color_scheme = (ColorScheme) color_scheme.get_int32 ();
                    }
                });
            } catch (Error e) {
                critical (e.message);
            }
        }
    }
}
