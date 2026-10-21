import { describe, it, expect } from '@ohos/hypium'
import { City, offsetMillisecondsToHours, supportedSystemTimezone } from '../main/ets/Data/DataSource'
import { restoreCities } from '../main/ets/Data/CityListLogic'

export default function localUnitTest() {
  describe('time-zone offsets', () => {
    it('converts representative winter and summer DST offsets', 0, () => {
      expect(offsetMillisecondsToHours(3600000)).assertEqual(1)
      expect(offsetMillisecondsToHours(7200000)).assertEqual(2)
    })

    it('preserves integer, half-hour, and Kathmandu quarter-hour offsets', 0, () => {
      expect(offsetMillisecondsToHours(3600000)).assertEqual(1)
      expect(offsetMillisecondsToHours(19800000)).assertEqual(5.5)
      expect(offsetMillisecondsToHours(20700000)).assertEqual(5.75)
    })

    it('includes Kathmandu with its IANA time-zone ID', 0, () => {
      const kathmandu = supportedSystemTimezone.find((city: City) => city.name === 'Kathmandu')
      expect(kathmandu?.timezone).assertEqual('Asia/Kathmandu')
    })
  })

  describe('saved city migration', () => {
    it('keeps first occurrences and saved order while upgrading zones', 0, () => {
      const saved: City[] = [
        { name: 'Warsaw', timezone: 'old-zone', headerWord: 'W' },
        { name: 'London', timezone: 'old-zone', headerWord: 'L' },
        { name: 'Warsaw', timezone: 'old-zone', headerWord: 'W' },
        { name: 'Unknown', timezone: 'invalid', headerWord: 'U' }
      ]
      const catalog: City[] = [
        { id: 'geonames:2643743', name: 'London', timezone: 'Europe/London', headerWord: 'L' },
        { id: 'geonames:756135', name: 'Warsaw', timezone: 'Europe/Warsaw', headerWord: 'W' }
      ]
      const restored = restoreCities(saved, catalog)
      expect(restored.length).assertEqual(2)
      expect(restored[0].name).assertEqual('Warsaw')
      expect(restored[0].timezone).assertEqual('Europe/Warsaw')
      expect(restored[0].id).assertEqual('geonames:756135')
      expect(restored[1].name).assertEqual('London')
    })

    it('prefers stable IDs and ignores invalid old entries', 0, () => {
      const saved: City[] = [
        { id: 'geonames:2', name: 'Old label', timezone: 'invalid', headerWord: 'O' },
        { id: 'missing', name: 'Current label', timezone: 'Bad/Zone', headerWord: 'C' }
      ]
      const catalog: City[] = [
        { id: 'geonames:2', name: 'Current label', timezone: 'Asia/Kathmandu', headerWord: 'C' }
      ]
      const restored = restoreCities(saved, catalog)
      expect(restored.length).assertEqual(1)
      expect(restored[0].name).assertEqual('Current label')
      expect(restored[0].timezone).assertEqual('Asia/Kathmandu')
    })
  })
}
