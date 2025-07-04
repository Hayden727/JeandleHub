#include <jni.h>
#include <stdio.h>
#include "MyClass.h"
#include <stdint.h>

JNIEXPORT void JNICALL Java_MyClass_printNativeAddress(JNIEnv* env, jobject obj) {
    printf("[JNI] Native address of obj: %p\n", obj);
    fflush(stdout);
}

JNIEXPORT jlong JNICALL Java_MyClass_getNativeAddress(JNIEnv* env, jobject obj) {
    return (jlong)(uintptr_t)obj;
}