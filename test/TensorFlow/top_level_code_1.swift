// RUN: %target-swift-frontend -Xllvm -tf-dump-intermediates -Xllvm -tf-strict-deabstraction -O -emit-sil -verify %s
// RUN: %target-swift-frontend -Xllvm -tf-dump-intermediates -Xllvm -tf-strict-deabstraction -O -emit-sil -verify %s | %FileCheck %s
import TensorFlow

// This test is intended to verify that all of the operations end up in-graph:
// that there are no host/accelerator copies generated.  This specifically
// handles checking for top level code.



// This is testing that we can promote dataflow edges between ops that involve
// top level variables.  Because they are visible and accessible to nested code,
// they are represented as global variables, and require special promotion
// logic.

// CHECK-LABEL: TFDeabstraction Result: main
// CHECK:  sil @main : $@convention(c) (Int32, UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>) -> Int32 {

// This test also verifies that the assignment inside of
// 'localFunctionTouchingGlobalVar' is properly deabstracted.
//
let one = Tensor<Float>(1.0)
var x = one
func localFunctionTouchingGlobalVar() {
  x = one
}
x += one
x += one
#if false  // FIXME: Re-enable when deabstraction is smarter.
localFunctionTouchingGlobalVar()       // reassigns one to x
#else
x = one
#endif
x -= one

let y = Tensor<Float>(2.0)
let y2 = y*y*y*y

// CHECK:   [[ONE:%.*]] = graph_op "tfc.scalarToTensor,s"
// CHECK:   [[ADD1:%.*]] = graph_op "Add,i,i"([[ONE]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>)
// CHECK:   [[ADD2:%.*]] = graph_op "Add,i,i"([[ADD1]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>)
// CHECK:   graph_op "Sub,i,i"([[ONE]] : $TensorHandle<Float>, [[ONE]] : $TensorHandle<Float>)
// CHECK:   [[TWO:%.*]] = graph_op "tfc.scalarToTensor
// CHECK:   [[MUL1:%.*]] = graph_op "Mul,i,i"([[TWO]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)
// CHECK:   [[MUL2:%.*]] = graph_op "Mul,i,i"([[MUL1]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)
// CHECK:   [[MUL3:%.*]] = graph_op "Mul,i,i"([[MUL2]] : $TensorHandle<Float>, [[TWO]] : $TensorHandle<Float>)

// b/76155918
let a: Tensor<Float> = [1, 2, 3]
let b: Tensor<Float> = [1, 2]

print(x)
print(y2)


// CHECK-LABEL: } // end sil function 'main'
