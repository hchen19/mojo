# ===----------------------------------------------------------------------=== #
#
# This file is Modular Inc proprietary.
#
# ===----------------------------------------------------------------------=== #
# RUN: %mojo -debug-level full %s | FileCheck %s

from math import exp

from memory import stack_allocation
from memory.buffer import (
    Buffer,
    NDBuffer,
    partial_simd_load,
    partial_simd_store,
)

from utils.index import StaticIntTuple
from utils.list import DimList


# CHECK-LABEL: test_partial_load_store
fn test_partial_load_store():
    print("== test_partial_load_store")
    # The total amount of data to allocate
    alias total_buffer_size: Int = 32

    var read_data = stack_allocation[
        total_buffer_size,
        DType.index,
        1,
    ]()

    var write_data = stack_allocation[
        total_buffer_size,
        DType.index,
        1,
    ]()

    var read_buffer = Buffer[
        DType.index,
        total_buffer_size,
    ](read_data)

    var write_buffer = Buffer[
        DType.index,
        total_buffer_size,
    ](write_data)

    for idx in range(total_buffer_size):
        # Fill read_bufer with 0->15
        read_buffer[idx] = idx
        # Fill write_buffer with 0
        write_buffer[idx] = 0

    # Test partial load:
    var partial_load_data = partial_simd_load[4](
        read_buffer.data.offset(1),
        1,
        3,
        99,  # idx  # lbound  # rbound  # pad value
    )
    # CHECK: [99, 2, 3, 99]
    print(partial_load_data)

    # Test partial store:
    partial_simd_store[4](
        write_buffer.data.offset(1),
        2,
        4,
        partial_load_data,  # idx  # lbound  # rbound
    )
    var partial_store_data = write_buffer.load[width=4](2)
    # CHECK: [0, 3, 99, 0]
    print(partial_store_data)

    # Test NDBuffer partial load store
    var read_nd_buffer = NDBuffer[
        DType.index,
        2,
        DimList(8, 4),
    ](read_data)

    var write_nd_buffer = NDBuffer[
        DType.index,
        2,
        DimList(8, 4),
    ](write_data)

    # Test partial load:
    var nd_partial_load_data = partial_simd_load[4](
        read_nd_buffer._offset(StaticIntTuple[2](3, 2)),
        0,
        2,
        123,  # lbound  # rbound  # pad value
    )
    # CHECK: [14, 15, 123, 123]
    print(nd_partial_load_data)

    # Test partial store
    partial_simd_store[4](
        write_nd_buffer._offset(StaticIntTuple[2](3, 1)),
        0,  # lbound
        3,  # rbound
        nd_partial_load_data,  # value
    )
    var nd_partial_store_data = write_nd_buffer.load[width=4](
        StaticIntTuple[2](3, 0)
    )

    # CHECK: [0, 14, 15, 123]
    print(nd_partial_store_data)


fn main():
    test_partial_load_store()
