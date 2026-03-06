/**
 * react-native-picture-selector — Example App
 *
 * Demonstrates all major picker features across platforms.
 */

import React, { useState } from 'react'
import {
  Alert,
  FlatList,
  Image,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native'

import {
  MediaType,
  PickerTheme,
  usePictureSelector,
  type MediaAsset,
} from 'react-native-picture-selector'

// ─────────────────────────────────────────────────────────────────────────────
// Demo scenarios
// ─────────────────────────────────────────────────────────────────────────────

const SCENARIOS = [
  {
    label: 'Pick single photo',
    action: 'pick',
    opts: { mediaType: MediaType.IMAGE, maxCount: 1 },
  },
  {
    label: 'Pick up to 9 photos/videos',
    action: 'pick',
    opts: { mediaType: MediaType.ALL, maxCount: 9 },
  },
  {
    label: 'Pick & crop (1:1)',
    action: 'pick',
    opts: {
      mediaType: MediaType.IMAGE,
      maxCount: 1,
      crop: { enabled: true, ratioX: 1, ratioY: 1 },
    },
  },
  {
    label: 'Pick & crop (free style)',
    action: 'pick',
    opts: {
      mediaType: MediaType.IMAGE,
      maxCount: 1,
      crop: { enabled: true, freeStyle: true },
    },
  },
  {
    label: 'Pick with compression',
    action: 'pick',
    opts: {
      mediaType: MediaType.IMAGE,
      maxCount: 3,
      compress: { enabled: true, quality: 0.6, maxWidth: 1280, maxHeight: 1280 },
    },
  },
  {
    label: 'Pick video (max 30s)',
    action: 'pick',
    opts: {
      mediaType: MediaType.VIDEO,
      maxCount: 1,
      maxVideoDuration: 30,
    },
  },
  {
    label: 'Camera — photo',
    action: 'shoot',
    opts: { mediaType: MediaType.IMAGE },
  },
  {
    label: 'Camera — video (max 60s)',
    action: 'shoot',
    opts: { mediaType: MediaType.VIDEO, maxVideoDuration: 60 },
  },
  {
    label: Platform.OS === 'android' ? 'WeChat theme (Android)' : 'Custom color (iOS)',
    action: 'pick',
    opts: {
      mediaType: MediaType.IMAGE,
      maxCount: 1,
      theme: Platform.OS === 'android' ? PickerTheme.WECHAT : PickerTheme.DEFAULT,
      themeColor: '#1DB954',
    },
  },
] as const

// ─────────────────────────────────────────────────────────────────────────────
// Asset card
// ─────────────────────────────────────────────────────────────────────────────

const AssetCard: React.FC<{ asset: MediaAsset }> = ({ asset }) => (
  <View style={styles.card}>
    {asset.type === 'image' ? (
      <Image source={{ uri: asset.uri }} style={styles.thumb} resizeMode="cover" />
    ) : (
      <View style={[styles.thumb, styles.videoThumb]}>
        <Text style={styles.videoIcon}>▶</Text>
      </View>
    )}
    <View style={styles.cardInfo}>
      <Text style={styles.cardTitle} numberOfLines={1}>{asset.fileName}</Text>
      <Text style={styles.cardMeta}>
        {asset.width}×{asset.height}px
        {asset.duration > 0 ? `  ${(asset.duration / 1000).toFixed(1)}s` : ''}
      </Text>
      <Text style={styles.cardMeta}>
        {(asset.fileSize / 1024).toFixed(1)} KB · {asset.mimeType}
      </Text>
      {asset.editedUri ? <Text style={styles.edited}>✓ Edited</Text> : null}
      {asset.isOriginal ? <Text style={styles.edited}>✓ Original</Text> : null}
    </View>
  </View>
)

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

export default function App() {
  const { assets, loading, error, pick, shoot, clear } = usePictureSelector()
  const [activeLabel, setActiveLabel] = useState<string | null>(null)

  const run = async (
    action: 'pick' | 'shoot',
    opts: object,
    label: string
  ) => {
    setActiveLabel(label)
    try {
      if (action === 'pick') {
        await pick(opts as any)
      } else {
        await shoot(opts as any)
      }
    } catch (e: any) {
      if (e?.code !== 'CANCELLED') {
        Alert.alert('Picker error', e?.message ?? String(e))
      }
    } finally {
      setActiveLabel(null)
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />

      <Text style={styles.header}>react-native-picture-selector</Text>
      <Text style={styles.sub}>Nitro Modules • {Platform.OS}</Text>

      <ScrollView style={styles.scenarioList} showsVerticalScrollIndicator={false}>
        {SCENARIOS.map((s) => {
          const busy = loading && activeLabel === s.label
          return (
            <Pressable
              key={s.label}
              style={({ pressed }) => [
                styles.btn,
                pressed && styles.btnPressed,
                busy && styles.btnBusy,
              ]}
              onPress={() => run(s.action as any, s.opts, s.label)}
              disabled={loading}
            >
              <Text style={styles.btnText}>
                {busy ? '⏳ ' : ''}{s.label}
              </Text>
            </Pressable>
          )
        })}
      </ScrollView>

      {error != null && (
        <View style={styles.errorBox}>
          <Text style={styles.errorText}>Error [{error.code}]: {error.message}</Text>
        </View>
      )}

      {assets.length > 0 && (
        <View style={styles.results}>
          <View style={styles.resultsHeader}>
            <Text style={styles.resultsTitle}>{assets.length} selected</Text>
            <Pressable onPress={clear} style={styles.clearBtn}>
              <Text style={styles.clearText}>Clear</Text>
            </Pressable>
          </View>
          <FlatList
            data={assets}
            keyExtractor={(_, i) => String(i)}
            renderItem={({ item }) => <AssetCard asset={item} />}
            style={styles.assetList}
          />
        </View>
      )}
    </SafeAreaView>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8f8f8' },
  header: {
    fontSize: 18,
    fontWeight: '700',
    textAlign: 'center',
    marginTop: 16,
    color: '#1a1a1a',
  },
  sub: {
    fontSize: 13,
    color: '#888',
    textAlign: 'center',
    marginBottom: 12,
  },
  scenarioList: { flexGrow: 0, maxHeight: 340, paddingHorizontal: 16 },
  btn: {
    backgroundColor: '#007AFF',
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  btnPressed: { opacity: 0.7 },
  btnBusy: { backgroundColor: '#aaa' },
  btnText: { color: '#fff', fontWeight: '600', fontSize: 14 },
  errorBox: {
    margin: 12,
    padding: 12,
    backgroundColor: '#ffe0e0',
    borderRadius: 8,
  },
  errorText: { color: '#c00', fontSize: 13 },
  results: { flex: 1, marginTop: 8 },
  resultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginBottom: 6,
  },
  resultsTitle: { fontSize: 15, fontWeight: '600' },
  clearBtn: { padding: 6 },
  clearText: { color: '#007AFF', fontSize: 14 },
  assetList: { paddingHorizontal: 16 },
  card: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 10,
    marginBottom: 8,
    overflow: 'hidden',
    elevation: 1,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
  },
  thumb: { width: 72, height: 72 },
  videoThumb: {
    backgroundColor: '#222',
    alignItems: 'center',
    justifyContent: 'center',
  },
  videoIcon: { color: '#fff', fontSize: 24 },
  cardInfo: { flex: 1, padding: 10, justifyContent: 'center' },
  cardTitle: { fontSize: 13, fontWeight: '600', color: '#1a1a1a', marginBottom: 2 },
  cardMeta: { fontSize: 11, color: '#888', marginBottom: 1 },
  edited: { fontSize: 11, color: '#1DB954', marginTop: 2 },
})
