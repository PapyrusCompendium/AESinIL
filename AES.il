.assembly extern mscorlib
{
	.publickeytoken = (b7 7a 5c 56 19 34 e0 89)
	.ver 4:0:0:0
}
.assembly extern System.Core
{
	.publickeytoken = (b7 7a 5c 56 19 34 e0 89)
	.ver 4:0:0:0
}
.assembly Program {.ver 1:0:0:0}

.namespace AESinIL
{
    .class public auto ansi beforefieldinit Program
    {
        .method public hidebysig static void Main(string[] args) cil managed
        {
            .maxstack 4
            .entrypoint
            .locals init(
                [0] string,
                [1] string
            )

            ldstr       "AES in IL, I wrote this simply to practice more with writing in IL."
            call        void [mscorlib]System.Console::WriteLine(string)

            ldstr       "Password: "
            call        void [mscorlib]System.Console::Write(string)
            
            call        string [mscorlib]System.Console::ReadLine()
            stloc.0     //Load the password to our locals.

            ldstr       "Plain Text: "
            call        void [mscorlib]System.Console::Write(string)

            call        string [mscorlib]System.Console::ReadLine()
            stloc.1     //Load the plaintext into our locals.

            ldstr       "Encrypting..."
            call        void [mscorlib]System.Console::WriteLine(string)

            ldloc.1
            ldloc.0
            call        void AESinIL.Cryptography::RoundTrip(string, string)
            ret
        }

        .method public hidebysig specialname instance void .ctor() cil managed
        {
            .maxstack 1
            ldarg.0
            call        instance void [mscorlib]System.Object::.ctor()
            ret
        }
    }

    .class public auto ansi beforefieldinit Cryptography
    {
                .method public hidebysig static void RoundTrip(string data, string password) cil managed
        {
            .maxstack 4
            .locals init(
                [0] uint8[]
            )
            
            call        class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()
            ldarg.0     //Convert our string into a uint8[].
            callvirt    instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)

            ldarg.1     //Encrypt the data[] using the password from the user.
            ldc.i4 256
            call        uint8[] ConsoleApplication1.Program::Encrypt(uint8[], string, int32)
            stloc.0     //Save this byte array for later use.

            ldloc.0     //Outout the encrypted data to the user.
            call        string [mscorlib]System.Convert::ToBase64String(uint8[])
            call        void [mscorlib]System.Console::WriteLine(string)

            call        class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()

            ldloc.0
            ldarg.1
            ldc.i4 256
            call        uint8[] ConsoleApplication1.Program::Decrypt(uint8[], string, int32)
                        //Convert our byte[] back into a string.

            callvirt    instance string [mscorlib]System.Text.Encoding::GetString(uint8[])
            call        void [mscorlib]System.Console::WriteLine(string)
            ret
        }

        .method public hidebysig static uint8[] Decrypt(uint8[] data, string password, [opt] int32 keySize) cil managed
        {
            .param[3] = int32(256)
            .maxstack 8
            .locals init(
                [0] class [System.Core]System.Security.Cryptography.AesCryptoServiceProvider,
                [1] uint8[], //This is our "StrippedData" byte[]
                [2] uint8[] //This is the returned data array.
            )
            
            newobj      instance void [System.Core]System.Security.Cryptography.AesCryptoServiceProvider::.ctor()
            stloc.0     //We are going to take the instance off the stack and into our locals.

            ldloc.0     //we need the instance for the next few instructions, we will load it each time. This time we need it for cipher mode, argument 0.
            ldc.i4.1    //fast way to load 32 bit integral value of 1 onto the stack. We are going to use it when setting the cipher mode to CBC(1), argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Mode(valuetype [mscorlib]System.Security.Cryptography.CipherMode)

            ldloc.0     //Setting the padding mode, argument 0.
            ldc.i4.2    //Padding mode PKCS7(2), argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Padding(valuetype [mscorlib]System.Security.Cryptography.PaddingMode)

            ldloc.0     //Setting the keysize, argument 0.
            ldarg.2     //This is the keysize as defined in the invocation of the method, argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_KeySize(int32)
            
            ldc.i4.s 16
            newarr      [mscorlib]System.Byte
            stloc.1

            ldarg.0     //Originally I had used linq here, however linq looks like a mess in IL.
            ldc.i4.0    //Load 4 byte integer, constant of 0.
            ldloc.1     //Destination.

            ldc.i4.0
            ldc.i4.s 16 //Copy the first 16 bytes from the cipher text, into the Init Vector.
            call        void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)

            ldloc.0     //Set the IV in our AesCryptoServiceProvider
            ldloc.1
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_IV(uint8[])

            ldarg.0     //length of the cipher text.
            ldlen
            conv.i4     //Convert the length to a 4 byte integer.

            ldc.i4.s 16
            sub         //Subtract 16 from the length of the cipher text data, and create a new array of this length.
            newarr      [mscorlib]System.Byte
            stloc.1     //Re-assign the value to our locals.

            ldarg.0     //The data we are copying from.
            ldc.i4.s 16 //Source Offset.
            ldloc.1     //Destination array.
            ldc.i4.0    //Destination offset.

            ldloc.1     //Length bytes to copy from the data[] to our destination array.
            ldlen
            conv.i4

            call        void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)

            ldloc.0     //CryptoProvider instance.
            ldarg.1     //Our password.
            ldc.i4.0    //The size of our byte array(0).
            newarr      [mscorlib]System.Byte
                        //Create a new byte array, push the stack.
            newobj      instance void [mscorlib]System.Security.Cryptography.PasswordDeriveBytes::.ctor(string, uint8[])

            ldarg.2     //Key size
            ldc.i4.8
            div         //Keysize divided by 8
            callvirt    instance uint8[] [mscorlib]System.Security.Cryptography.DeriveBytes::GetBytes(int32)
                        //Load (Keysize / 8) bytes onto the stack, from PasswordDeriveBytes.
                        //Then with our last stacked object, AesCryptoServiceProvider, call set_Key
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Key(uint8[])

            ldloc.1     //Create a new memory stream from our encrypted data[].
            newobj      instance void [mscorlib]System.IO.MemoryStream::.ctor(uint8[])
                        //Memory Stream is only being used once, do not make a local variable.

            ldloc.0     //Construct our ICryptoTransform.
            callvirt    instance class [mscorlib]System.Security.Cryptography.ICryptoTransform [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::CreateDecryptor()
                        //We are only using the CryptoTranform here, do not need a local variable.
            ldc.i4.0    //Create our CryptoStream with read mode, MemoryStream, ICryptoTransform, int32
            newobj      instance void [mscorlib]System.Security.Cryptography.CryptoStream::.ctor(class [mscorlib]System.IO.Stream, class [mscorlib]System.Security.Cryptography.ICryptoTransform, valuetype [mscorlib]System.Security.Cryptography.CryptoStreamMode)
                        //Crypto Stream is only being used here, do not need a local variable.
                        
            ldloc.1     //Destination array.
            ldc.i4.0    //Offset.

            ldloc.1
            ldlen
            conv.i4     //Number of bytes to read.
            
            callvirt    instance int32 [mscorlib]System.IO.Stream::Read(uint8[], int32, int32)
            newarr      [mscorlib]System.Byte
            stloc.2     //Create byte[] with the size of the number of bytes read.

            ldloc.1     //The source array. 
            ldc.i4.0    //Offset.
            ldloc.2     //Destination Array.
            ldc.i4.0    //Offset.

            ldloc.2     //Number of bytes to copy.
            ldlen
            conv.i4
                        //Copy over the number of bytes read from the crypto stream, when decrypting.
            call        void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)

            ldloc.2
            ret         //return the decrypted data.
        }
        
        .method public hidebysig static uint8[] Encrypt(uint8[] data, string password, [opt] int32 keySize) cil managed
        {
            .param[3] = int32(256)
            .maxstack 5
            .locals init(
                [0] class [System.Core]System.Security.Cryptography.AesCryptoServiceProvider,
                [1] class [mscorlib]System.Security.Cryptography.ICryptoTransform,
                [2] class [mscorlib]System.IO.MemoryStream,
                [3] class [mscorlib]System.Security.Cryptography.CryptoStream,
                [4] uint8[]
            ) 

            newobj      instance void [System.Core]System.Security.Cryptography.AesCryptoServiceProvider::.ctor()
            stloc.0     //We are going to take the instance off the stack and into our locals.

            ldloc.0     //we need the instance for the next few instructions, we will load it each time. This time we need it for cipher mode, argument 0.
            ldc.i4.1    //fast way to load 32 bit integral value of 1 onto the stack. We are going to use it when setting the cipher mode to CBC(1), argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Mode(valuetype [mscorlib]System.Security.Cryptography.CipherMode)

            ldloc.0     //Setting the padding mode, argument 0.
            ldc.i4.2    //Padding mode PKCS7(2), argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Padding(valuetype [mscorlib]System.Security.Cryptography.PaddingMode)

            ldloc.0     //Setting the keysize, argument 0.
            ldarg.2     //This is the keysize as defined in the invocation of the method, argument 1.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_KeySize(int32)

            ldloc.0     //Creating an Init Vector, argument 0.
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::GenerateIV()

            ldloc.0
            ldarg.1     //Push the stack with our password.
            ldc.i4.0    //The size of our byte array(0), argument 0.
            newarr      [mscorlib]System.Byte
                        //Create a new byte array, push the stack.
            newobj      instance void [mscorlib]System.Security.Cryptography.PasswordDeriveBytes::.ctor(string, uint8[])

            ldarg.2     //Key size
            ldc.i4.8
            div         //Keysize divided by 8
            callvirt     instance uint8[] [mscorlib]System.Security.Cryptography.DeriveBytes::GetBytes(int32)
                        //Load (Keysize / 8) bytes onto the stack, from PasswordDeriveBytes.
                        //Then with our last stacked object, AesCryptoServiceProvider, call set_Key
            callvirt    instance void [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::set_Key(uint8[])

            ldloc.0
            callvirt    instance class [mscorlib]System.Security.Cryptography.ICryptoTransform [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::CreateEncryptor()
            stloc.1     //Pop the stack, and load a value into local 1. (ICryptoTransform)

            newobj      instance void [mscorlib]System.IO.MemoryStream::.ctor()
            stloc.2     //Pop the stack, and load a value into local 2. (MemoryStream)

            ldloc.2     //Load our MemoryStream.
            ldloc.1     //Load our ICryptoTransform.
            ldc.i4.1    //CryptoStreamMode.Write(1).
            newobj      instance void [mscorlib]System.Security.Cryptography.CryptoStream::.ctor(class [mscorlib]System.IO.Stream, class [mscorlib]System.Security.Cryptography.ICryptoTransform, valuetype [mscorlib]System.Security.Cryptography.CryptoStreamMode)
            stloc.3     //Pop the stack, and load a value into local 3. (CryptoStream)

            ldloc.3     //Load the writer instance to top of the stack.
            ldarg.0     //Load our Data[].
            ldc.i4.0    //0, our write index.

            ldarg.0 
            ldlen       //Load the length of our data.
            conv.i4     //Convert the returned length to int32.
            callvirt    instance void [mscorlib]System.IO.Stream::Write(uint8[], int32, int32)

            ldloc.3     //Flush our CryptoStream.
            callvirt    instance void [mscorlib]System.Security.Cryptography.CryptoStream::FlushFinalBlock()

            ldloc.2     //Get the length of our MemoryStream.
            callvirt    instance int64 [mscorlib]System.IO.Stream::get_Length()

            ldc.i8 16   //Our AES Blocksize / 8 = 16 (Load as int64)
            add         //Add our MemoryStream.Length and 16
            conv.ovf.i  //Convert our two added int64's to native int (int32 in this case).

            newarr      [mscorlib]System.Byte
                        //Create a new, empty, byte array of our IV and encrypted Data Length.
            stloc.s 4   //Pop the stack and load the empty byte array into local 4.

            ldloc.0     //Load our IV[] onto the stack.
            callvirt    instance uint8[] [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::get_IV()

            ldc.i4.0    //Load constant 0.
            ldloc.s 4   //Load our empty byte[], this is the destination array argument.
            ldc.i4.0

            ldloc.0     //Load our CryptoProvider, and get the IV length.
            callvirt    instance uint8[] [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::get_IV()
            ldlen       //Push the length.
            conv.i4     //Convert the length to int32
                        //Copy the IV from our CryptoProvider to our destination array.
            call        void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)

            ldloc.2     //Convert our MemoryStream to an array, and load onto the stack.
            callvirt    instance uint8[] [mscorlib]System.IO.MemoryStream::ToArray()

            ldc.i4.0    //Load constant 0.
            ldloc.s 4   //this is the destination array argument.

            ldloc.0     //Load our CryptoProvider, and get the IV length.
            callvirt    instance uint8[] [mscorlib]System.Security.Cryptography.SymmetricAlgorithm::get_IV()
            ldlen       //Push the length.
            conv.i4     //Convert the length to int32

            ldloc.2
            callvirt    instance uint8[] [mscorlib]System.IO.MemoryStream::ToArray()
            ldlen
            conv.i4 
                        //Copy the encrypted bytes from our MemoryStream to our destination array. Start after the IV length.
            call        void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)

            ldloc.3     //Dispose of the CryptoStream.
            callvirt    instance void [mscorlib]System.IDisposable::Dispose()
            ldloc.2     //Dispose of the MemoryStream.
            callvirt    instance void [mscorlib]System.IDisposable::Dispose()

            ldloc.s 4
            ret         //Return our destination array.
        }
    }
}
