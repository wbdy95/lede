'use strict';
'require baseclass';
'require rpc';

/**
 * WireGuard Dashboard API
 * Package: luci-app-wireguard-dashboard
 * RPCD object: wireguard-dashboard
 */

var callStatus = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'status',
	expect: { }
});

var callGetInterfaces = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'interfaces',
	expect: { }
});

var callGetPeers = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'peers',
	expect: { }
});

var callGetTraffic = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'traffic',
	expect: { }
});

var callGetConfig = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'config',
	expect: { }
});

var callGenerateQR = rpc.declare({
	object: 'wireguard-dashboard',
	method: 'generate_qr',
	params: ['interface', 'peer'],
	expect: { }
});

function formatBytes(bytes) {
	if (bytes === 0) return '0 B';
	var k = 1024;
	var sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
	var i = Math.floor(Math.log(bytes) / Math.log(k));
	return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatLastHandshake(timestamp) {
	if (!timestamp || timestamp === 0) return '从未';
	var now = Math.floor(Date.now() / 1000);
	var diff = now - timestamp;
	if (diff < 60) return diff + '秒前';
	if (diff < 3600) return Math.floor(diff / 60) + '分钟前';
	if (diff < 86400) return Math.floor(diff / 3600) + '小时前';
	return Math.floor(diff / 86400) + '天前';
}

function shortenKey(key, length) {
	if (!key) return '';
	if (key.length <= length) return key;
	return key.substring(0, length) + '...';
}

function getPeerStatusClass(status) {
	switch(status) {
		case 'active':
			return 'status-active';
		case 'idle':
			return 'status-idle';
		case 'inactive':
			return 'status-inactive';
		default:
			return 'status-unknown';
	}
}

function getAllData() {
	return Promise.all([
		callStatus().catch(function(e) { return { error: e }; }),
		callGetInterfaces().catch(function(e) { return { interfaces: [] }; }),
		callGetPeers().catch(function(e) { return { peers: [] }; }),
		callGetTraffic().catch(function(e) { return { interfaces: [], total_rx: 0, total_tx: 0 }; }),
		callGetConfig().catch(function(e) { return { interfaces: [] }; })
	]).then(function(results) {
		return {
			status: results[0],
			interfaces: results[1],
			peers: results[2],
			traffic: results[3],
			config: results[4]
		};
	});
}

return baseclass.extend({
	getStatus: callStatus,
	getInterfaces: callGetInterfaces,
	getPeers: callGetPeers,
	getTraffic: callGetTraffic,
	getConfig: callGetConfig,
	generateQR: callGenerateQR,
	getAllData: getAllData,
	formatBytes: formatBytes,
	formatLastHandshake: formatLastHandshake,
	shortenKey: shortenKey,
	getPeerStatusClass: getPeerStatusClass
});
