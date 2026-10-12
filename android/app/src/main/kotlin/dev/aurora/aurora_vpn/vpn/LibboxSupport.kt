package dev.aurora.aurora_vpn.vpn

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.RoutePrefix
import io.nekohasekai.libbox.StringIterator
import java.net.InetAddress
import io.nekohasekai.libbox.NetworkInterface as BoxInterface

/** Kotlin → gomobile iterator adapters. */
class StringArray(private val items: List<String>) : StringIterator {
    private val it = items.iterator()

    override fun len(): Int = items.size

    override fun hasNext(): Boolean = it.hasNext()

    override fun next(): String = it.next()
}

class InterfaceArray(private val it: Iterator<BoxInterface>) : NetworkInterfaceIterator {
    override fun hasNext(): Boolean = it.hasNext()

    override fun next(): BoxInterface = it.next()
}

fun StringIterator.toList(): List<String> {
    val out = mutableListOf<String>()
    while (hasNext()) out += next()
    return out
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix(): IpPrefix = IpPrefix(InetAddress.getByName(address()), prefix())
