package dev.aurora.aurora_vpn.vpn

import android.net.DnsResolver
import android.os.Build
import android.os.CancellationSignal
import android.system.ErrnoException
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.ExchangeContext
import io.nekohasekai.libbox.LocalDNSTransport
import java.net.InetAddress
import java.net.UnknownHostException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * sing-box's `local` DNS server on Android: queries the system resolver of the
 * underlying network (Go's own resolver has no /etc/resolv.conf here).
 */
class LocalResolver(private val monitor: NetworkMonitor) : LocalDNSTransport {
    private val executor = Executors.newCachedThreadPool()

    override fun raw(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun exchange(ctx: ExchangeContext, message: ByteArray) {
        val network = monitor.defaultNetwork ?: error("missing default network")
        await(ctx) { signal, done ->
            DnsResolver.getInstance().rawQuery(
                network,
                message,
                DnsResolver.FLAG_NO_RETRY,
                executor,
                signal,
                object : DnsResolver.Callback<ByteArray> {
                    override fun onAnswer(answer: ByteArray, rcode: Int) {
                        if (rcode == 0) ctx.rawSuccess(answer) else ctx.errorCode(rcode)
                        done()
                    }

                    override fun onError(error: DnsResolver.DnsException) {
                        ctx.fail(error)
                        done()
                    }
                },
            )
        }
    }

    override fun lookup(ctx: ExchangeContext, network: String, domain: String) {
        val net = monitor.defaultNetwork ?: error("missing default network")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val answer = try {
                net.getAllByName(domain)
            } catch (_: UnknownHostException) {
                ctx.errorCode(RCODE_NXDOMAIN)
                return
            }
            ctx.success(answer.mapNotNull { it.hostAddress }.joinToString("\n"))
            return
        }
        await(ctx) { signal, done ->
            val callback = object : DnsResolver.Callback<List<InetAddress>> {
                override fun onAnswer(answer: List<InetAddress>, rcode: Int) {
                    if (rcode == 0) {
                        ctx.success(answer.mapNotNull { it.hostAddress }.joinToString("\n"))
                    } else {
                        ctx.errorCode(rcode)
                    }
                    done()
                }

                override fun onError(error: DnsResolver.DnsException) {
                    ctx.fail(error)
                    done()
                }
            }
            val type = when {
                network.endsWith("4") -> DnsResolver.TYPE_A
                network.endsWith("6") -> DnsResolver.TYPE_AAAA
                else -> null
            }
            if (type != null) {
                DnsResolver.getInstance().query(
                    net, domain, type, DnsResolver.FLAG_NO_RETRY, executor, signal, callback,
                )
            } else {
                DnsResolver.getInstance().query(
                    net, domain, DnsResolver.FLAG_NO_RETRY, executor, signal, callback,
                )
            }
        }
    }

    /** Runs [block] and blocks the (Go) caller until it calls `done` or is cancelled. */
    private fun await(ctx: ExchangeContext, block: (CancellationSignal, () -> Unit) -> Unit) {
        val latch = CountDownLatch(1)
        val signal = CancellationSignal()
        ctx.onCancel {
            signal.cancel()
            latch.countDown()
        }
        block(signal) { latch.countDown() }
        latch.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)
    }

    private fun ExchangeContext.fail(error: DnsResolver.DnsException) {
        val cause = error.cause
        if (cause is ErrnoException) errnoCode(cause.errno) else errorCode(RCODE_SERVFAIL)
    }

    private companion object {
        const val RCODE_SERVFAIL = 2
        const val RCODE_NXDOMAIN = 3
        const val TIMEOUT_SECONDS = 15L
    }
}
