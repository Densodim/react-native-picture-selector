# PictureSelector
-keep class com.luck.picture.lib.** { *; }
-keep class com.luck.lib.camerax.** { *; }

# uCrop
-dontwarn com.yalantis.ucrop**
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

# Glide
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
  <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# Nitro bridge
-keep class com.margelo.pictureselector.** { *; }
