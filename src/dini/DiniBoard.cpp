#include <jni.h>
#include "ae_lib.hpp"

using namespace ae;

namespace {
  AeLib  lib;
}


#ifndef _Included_me_preusser_q27_DiniBoard
#define _Included_me_preusser_q27_DiniBoard

/*
 * Class:     me_preusser_q27_DiniBoard
 * Method:    write0
 * Signature: (IJI)V
 */
extern "C" JNIEXPORT void JNICALL
Java_me_preusser_q27_DiniBoard_write0(JNIEnv *const  env, jclass const  klass,
	jint const  board, jlong const  addr, jint const  val) {
  lib.device(board).regwrite_boardspace_dword(addr, val);
}

/*
 * Class:     me_preusser_q27_DiniBoard
 * Method:    read0
 * Signature: (IJ)I
 */
extern "C" JNIEXPORT jint JNICALL
Java_me_preusser_q27_DiniBoard_read0(JNIEnv *const  env, jclass const  klass,
	jint const  board, jlong const  addr) {
  return  lib.device(board).regread_boardspace_dword(addr);
}

/*
 * Class:     me_preusser_q27_DiniBoard
 * Method:    awaitInterrupt0
 * Signature: (IJI)V
 */
extern "C" JNIEXPORT void JNICALL
Java_me_preusser_q27_DiniBoard_awaitInterrupt0(JNIEnv *const  env, jclass const  klass,
	jint const  board, jlong const  mask, jint const  timeout) {
  lib.device(board).wait_on_interrupt(mask, timeout);
}

#endif
