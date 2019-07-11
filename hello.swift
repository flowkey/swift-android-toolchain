import Dispatch
import Glibc

let sem = DispatchSemaphore(value: 2)

print("Hello")


DispatchQueue.global(qos: .background).async {
    print("Background")
    sem.signal()
}

sem.wait()

print("Done")

// let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: 25);
// ptr[0] = 104; ptr[1] = 101; ptr[2] = 108; ptr[3] = 108; ptr[4] = 111; ptr[5] = 32; ptr[6] = 102; ptr[7] = 114; ptr[8] = 111; ptr[9] = 109; ptr[10] = 32; ptr[11] = 97; ptr[12] = 32; ptr[13] = 114; ptr[14] = 97; ptr[15] = 119; ptr[16] = 32; ptr[17] = 112; ptr[18] = 111; ptr[19] = 105; ptr[20] = 110; ptr[21] = 116; ptr[22] = 101; ptr[23] = 114; ptr[24] = 0
// puts(ptr)
// ptr.deallocate()

// exit(2 * 2 + 5)
