#ifndef _Included_me_preusser_q27_DiniSolver
#define _Included_me_preusser_q27_DiniSolver

#include <jni.h>
#include "ae_lib.hpp"


using namespace ae;

namespace {
  AeLib  lib;
}


/*
 * Class:     me_preusser_q27_DiniSolver
 * Method:    _setupFPGA
 * Signature: (I)V
 */
extern "C" JNIEXPORT void JNICALL
Java_me_preusser_q27_DiniSolver__1setupFPGA(JNIEnv *const  env, jclass const  klass, jint const  devnum) {
  AeDevice &dev = lib.device(devnum);

  // Clear and disable input interrupt
  dev.regwrite_boardspace_dword(0, 0);
  // Enable output interrupt
  dev.regwrite_boardspace_dword(4, 3);
}

/*
 * Class:     me_preusser_q27_DiniSolver
 * Method:    _writeFPGA
 * Signature: (II)V
 */
extern "C" JNIEXPORT void JNICALL
Java_me_preusser_q27_DiniSolver__1writeFPGA(JNIEnv *const  env, jclass const  klass, jint const  devnum, jint const  b) {
   AeDevice &dev = lib.device(devnum);

   dev.regwrite_boardspace_dword(8, b);
}

/*
 * Class:     me_preusser_q27_DiniSolver
 * Method:    _readFPGA
 * Signature: (I)I
 */
extern "C" JNIEXPORT jint JNICALL
Java_me_preusser_q27_DiniSolver__1readFPGA(JNIEnv *const  env, jclass const  klass, jint const  devnum) {
   AeDevice &dev = lib.device(devnum);

   jclass  const  clsThread     = env->FindClass("java/lang/Thread");
   jobject const  currentThread = env->CallStaticObjectMethod(clsThread,
                    env->GetMethodID(clsThread, "currentThread", "()Ljava/lang/Thread;"));
   jmethodID const  mthInterrupted = env->GetMethodID(clsThread, "isInterrupted", "()Z");

   while(true) {
     int32_t const  val = dev.regread_boardspace_dword(0x8);
     if(val >= 0)  return  val & 0xFF;
     dev.wait_on_interrupt(UINT64_C(0x0100000000), 10u);
     if(env->CallBooleanMethod(currentThread, mthInterrupted))  return -1;
   }
}

#endif
