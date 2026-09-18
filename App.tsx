import React, { useCallback, useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts, InstrumentSerif_400Regular } from '@expo-google-fonts/instrument-serif';
import {
  Archivo_400Regular,
  Archivo_500Medium,
  Archivo_600SemiBold,
  Archivo_700Bold,
  Archivo_800ExtraBold,
} from '@expo-google-fonts/archivo';

import { HomeScreen } from './src/screens/HomeScreen';
import { color } from './src/theme/tokens';

void SplashScreen.preventAutoHideAsync();

export default function App() {
  // The serif/sans contrast carries the product's character, so the UI waits
  // for both families rather than flashing a system fallback.
  const [fontsLoaded, fontError] = useFonts({
    InstrumentSerif_400Regular,
    Archivo_400Regular,
    Archivo_500Medium,
    Archivo_600SemiBold,
    Archivo_700Bold,
    Archivo_800ExtraBold,
  });

  const ready = fontsLoaded || fontError !== null;

  useEffect(() => {
    if (ready) void SplashScreen.hideAsync();
  }, [ready]);

  const onLayout = useCallback(() => {
    if (ready) void SplashScreen.hideAsync();
  }, [ready]);

  if (!ready) return null;

  return (
    // Required by react-native-gesture-handler, which the draggable card
    // grid depends on for its long-press-to-reorder gesture.
    <GestureHandlerRootView style={styles.root}>
      <SafeAreaProvider>
        <View style={styles.root} onLayout={onLayout}>
          <StatusBar style="dark" />
          <HomeScreen />
        </View>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: color.surface },
});
