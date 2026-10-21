import { City, getCityKey } from './DataSource'

// Preserve the first valid saved occurrence and its position while upgrading catalog entries.
export function restoreCities(savedCities: City[], catalog: City[]): City[] {
  const ids = new Set<string>()
  const restored: City[] = []
  for (const saved of savedCities) {
    let current: City | undefined
    if (saved.id) {
      current = catalog.find((city: City) => city.id === saved.id)
    } else {
      current = catalog.find((city: City) => city.name === saved.name && city.timezone === saved.timezone)
      if (!current) {
        current = catalog.find((city: City) => city.name === saved.name)
      }
    }
    if (!current) {
      continue
    }
    const key = getCityKey(current)
    if (ids.has(key)) {
      continue
    }
    ids.add(key)
    restored.push(current)
  }
  return restored
}
