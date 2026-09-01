# Pyrit: GPU/CPU WPA/WPA2-PSK cracking (JPaulMora's Python 3 fork). Its
# cpyrit._cpyrit_cpu C extension was never fully ported off the Python 2 C-API,
# so postPatch finishes the port: PyString_* -> PyBytes_* (this module handles
# binary PMK/key data throughout), and the module init to PyModule_Create.
{ lib, python3Packages, fetchFromGitHub, openssl, libpcap, zlib, perl }:

python3Packages.buildPythonApplication {
  # Built against Python 3.11 (see callPackage): pyrit's setup.py needs distutils,
  # removed in 3.12+. It is a self-contained CLI, so its interpreter is private.
  pname = "pyrit";
  version = "0.5.1-unstable";
  format = "setuptools";

  # Pin an exact commit, never a branch name: fetchFromGitHub is a fixed-output
  # derivation, so `rev = "master"` breaks with a hash mismatch the moment
  # upstream master moves (which is what took the wifi cache build down). This
  # rev is the last commit before upstream's 2026-08-31 "Restore Python 2.7
  # APIs" churn, and is the exact tree the postPatch py2->py3 port below was
  # written against: the later HEAD reverts the buffer-protocol code to py2
  # (bf_getreadbuffer / PyBuffer_FromObject / 4-field PyBufferProcs), which the
  # postPatch regexes do not match, so it must not be bumped blindly. Bump rev
  # and hash together via `nix flake prefetch github:JPaulMora/Pyrit/<rev>` only
  # after re-checking the postPatch still applies.
  src = fetchFromGitHub {
    owner = "JPaulMora";
    repo = "Pyrit";
    rev = "478df449ce48f99bc717dc6a36a51f719714eaa1";
    hash = "sha256-nc5TS4CFnG2t0JZRk9KKwIUY5Me111DShYx3k6atbUk=";
  };

  nativeBuildInputs = [ perl ];
  buildInputs = [ openssl libpcap zlib ];
  # Old C extension: gcc-14+ promotes these to errors by default (typed method
  # slots vs PyObject*, and the odd int/pointer return in legacy code paths).
  env.NIX_CFLAGS_COMPILE = "-Wno-error -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration";
  propagatedBuildInputs = with python3Packages; [ scapy ];
  doCheck = false;
  pythonImportsCheck = [ "cpyrit" "cpyrit._cpyrit_cpu" ];

  postPatch = ''
    f=cpyrit/_cpyrit_cpu.c
    # py2 `PyObject_HEAD_INIT(NULL) 0, /*ob_size*/` shifts every PyTypeObject
    # field by one in py3; use the var-object head macro (all 6 type structs).
    perl -0777 -i -pe 's/PyObject_HEAD_INIT\(NULL\)\s*\n\s*0,\s*\/\*ob_size\*\//PyVarObject_HEAD_INIT(NULL, 0)/g' "$f"
    # PyString_* split into PyBytes_* (binary) in Python 3; this extension's
    # strings are all binary key material.
    perl -0777 -i -pe 's/#include <openssl\/sha.h>/#include <openssl\/sha.h>\n#define PyString_FromStringAndSize PyBytes_FromStringAndSize\n#define PyString_FromString PyBytes_FromString\n#define PyString_AsString PyBytes_AsString\n#define PyString_AsStringAndSize PyBytes_AsStringAndSize\n#define PyString_Size PyBytes_Size\n#define PyString_Check PyBytes_Check\n#define PyString_AS_STRING PyBytes_AS_STRING\n#define PyString_GET_SIZE PyBytes_GET_SIZE/' "$f"
    # Module init: py3 signature, PyModule_Create, and NULL returns on failure.
    perl -0777 -i -pe 's/init_cpyrit_cpu\(void\)/PyInit__cpyrit_cpu(void)/' "$f"
    perl -0777 -i -pe 's/m = Py_InitModule\("_cpyrit_cpu", CPyritCPUMethods\);/static struct PyModuleDef _cpyrit_cpu_moduledef = { PyModuleDef_HEAD_INIT, "_cpyrit_cpu", NULL, -1, CPyritCPUMethods }; m = PyModule_Create(&_cpyrit_cpu_moduledef);/' "$f"
    perl -0777 -i -pe 's/(PyType_Ready\(&\w+\) < 0\)\s*\n\s*)return;/''${1}return NULL;/gs' "$f"
    perl -0777 -i -pe 's/(PyModule_AddStringConstant\(m, "VERSION", VERSION\);\s*\n)\}/''${1}    return m;\n}/' "$f"

    # Port the old py2 buffer protocol (bf_getreadbuffer/getsegcount, removed in
    # py3) to the modern Py_buffer API, at the CowpattyResult provider and the two
    # consumer sites that read a caller-supplied PMK buffer.
    perl -0777 -i -pe 's/PyBuffer_Check\(pmkbuffer_obj\)/PyObject_CheckBuffer(pmkbuffer_obj)/g' "$f"
    perl -0777 -i -pe 's/pb = pmkbuffer_obj->ob_type->tp_as_buffer;\s*\n\s*buffersize = \(\*pb->bf_getbuffer\)\(pmkbuffer_obj, 0, \(void\*\*\)&t\);/Py_buffer _pybuf; if (PyObject_GetBuffer(pmkbuffer_obj, &_pybuf, PyBUF_SIMPLE) != 0) { Py_DECREF(pmkbuffer_obj); return NULL; } t = _pybuf.buf; buffersize = _pybuf.len; PyBuffer_Release(&_pybuf);/g' "$f"
    perl -0777 -i -pe 's/static Py_ssize_t\nCowpattyResult_bf_getreadbuffer\(CowpattyResult\* self, Py_ssize_t segment, void \*\*ptrptr\)\n\{.*?\n\}\n\nstatic Py_ssize_t\nCowpattyResult_bf_getsegcount\(CowpattyResult\* self, Py_ssize_t \*lenp\)\n\{.*?\n\}/static int\nCowpattyResult_bf_getbuffer(CowpattyResult* self, Py_buffer *view, int flags)\n{\n    return PyBuffer_FillInfo(view, (PyObject*)self, self->buffer, self->itemcount * 32, 1, flags);\n}/s' "$f"
    perl -0777 -i -pe 's/static PyBufferProcs CowpattyResults_buffer_procs = \{.*?\};/static PyBufferProcs CowpattyResults_buffer_procs = {\n    (getbufferproc)CowpattyResult_bf_getbuffer,\n    0\n};/s' "$f"
  '';

  meta = {
    description = "WPA/WPA2-PSK GPU/CPU cracking suite (Python 3, C extension ported off the py2 C-API)";
    homepage = "https://github.com/JPaulMora/Pyrit";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "pyrit";
  };
}
