# Inkotes ProGuard/R8 混淆规则

# Flutter 官方模板建议：Android embedding 无需额外规则。
# 若启用混淆后出现崩溃，按崩溃堆栈在下方添加对应 keep 规则。

# pdfrx（pdfium 原生库）：原生库不参与混淆；
# 其 Dart 侧经 FFI 绑定，通常无需 keep。若出现 JNI 相关崩溃，取消下行注释：
# -keep class com.github.pdfrx.** { *; }
