// ittyOS basic YARA rules.
// These are simple indicators, not a full virus database: they can give false
// positives, check every finding by hand. Add your own rules to /etc/ittyos/yara/*.yar

rule EICAR_Test_File
{
    meta:
        description = "EICAR antivirus test string"
    strings:
        $e = "EICAR-STANDARD-ANTIVIRUS-TEST-FILE!"
    condition:
        $e
}

rule Suspicious_Reverse_Shell_Bash
{
    meta:
        description = "bash reverse shell over /dev/tcp"
    strings:
        $a = "bash -i >& /dev/tcp/"
        $b = "bash -i >& /dev/udp/"
    condition:
        any of them
}

rule Suspicious_Cryptominer_Strings
{
    meta:
        description = "typical cryptominer pool/client strings"
    strings:
        $a = "stratum+tcp://"
        $b = "stratum+ssl://"
        $c = "xmrig" nocase
        $d = "cryptonight" nocase
    condition:
        2 of them
}
