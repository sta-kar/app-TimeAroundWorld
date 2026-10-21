import { timestampToDate } from '../Utils/timeUtils'
import { City, getCityKey, getOffsetHours, supportedSystemTimezone } from '../Data/DataSource'
import { ListPage } from './ListPage'
import { systemDateTime } from '@kit.BasicServicesKit'
import { i18n } from '@kit.LocalizationKit'
import { restoreCities } from '../Data/CityListLogic'

PersistentStorage.persistProp<City[]>('cityList', [])

interface CityClock {
  city: City;
  offsetHours: number;
  differenceHours: number;
}

@Entry
@Component
struct Index {
  @State timeZone: string = ''
  @State currentTime: number = 0
  @State convertedDate: string = ''
  @State currentTimeZoneOffset: number = 0

  @State isEdit: boolean = false
  @StorageLink('cityList') cityList: City[] = []
  @State cityClocks: CityClock[] = []
  pathStack: NavPathStack = new NavPathStack()
  private intervalId: number = 0
  private scroller: Scroller = new Scroller()
  @Builder
  PagesMap(name: string) {
    if (name === 'ListPage') {
      ListPage()
    }
  }

  aboutToAppear(): void {
    // Upgrade previously stored entries, which held a region and fixed offset.
    this.cityList = restoreCities(this.cityList, supportedSystemTimezone)
    this.updateTime()
    if (this.intervalId === 0) {
      this.intervalId = setInterval(() => this.updateTime(), 60000)
    }
  }

  aboutToDisappear(): void {
    if (this.intervalId !== 0) {
      clearInterval(this.intervalId)
      this.intervalId = 0
    }
  }

  private updateTime(): void {
    try {
      const now = systemDateTime.getTime(false)
      const zone = i18n.getTimeZone().getID()
      this.currentTime = now
      this.convertedDate = timestampToDate(now)
      this.timeZone = zone
      this.currentTimeZoneOffset = getOffsetHours(zone, now)
      this.updateCityClocks(now, this.currentTimeZoneOffset)
    } catch (error) {
      console.error(`Could not update the clock: ${error}`)
    }
  }

  private updateCityClocks(timestamp: number, localOffset: number): void {
    const clocks: CityClock[] = []
    for (const city of this.cityList) {
      try {
        const offset = getOffsetHours(city.timezone, timestamp)
        clocks.push({ city: city, offsetHours: offset, differenceHours: offset - localOffset })
      } catch (error) {
        console.error(`Could not calculate the time for ${city.name}: ${error}`)
      }
    }
    this.cityClocks = clocks
  }

  private refreshCityClocks(): void {
    this.updateCityClocks(this.currentTime, this.currentTimeZoneOffset)
  }

  private removeCity(id: string): void {
    this.cityList = this.cityList.filter((city: City) => getCityKey(city) !== id)
    this.refreshCityClocks()
    if (this.cityList.length === 0) {
      this.isEdit = false
    }
  }

  private moveCity(from: number, to: number): void {
    if (from < 0 || from >= this.cityList.length ||
      to < 0 || to > this.cityList.length || from === to) {
      return
    }
    const reordered: City[] = [...this.cityList]
    const moved: City[] = reordered.splice(from, 1)
    reordered.splice(to, 0, moved[0])
    this.cityList = reordered
    this.refreshCityClocks()
  }

  private addCity(): void {
    this.pathStack.pushPathByName('ListPage', {}, (popInfo: PopInfo) => {
      const selected = popInfo.result as City | undefined
      const city = selected ? supportedSystemTimezone.find((item: City) => item.id === selected.id) : undefined
      if (city && !this.cityList.some((item: City) => getCityKey(item) === getCityKey(city))) {
        this.cityList = [...this.cityList, city]
        this.refreshCityClocks()
      }
    })
  }

  @Builder
  CityRow(item: CityClock) {
    Row({ space: 12 }) {
      if (this.isEdit) {
        Button() {
          Image($r('app.media.remove_icon'))
            .width(20).height(20)
        }
        .width(38).height(38)
        .backgroundColor('#FF27B7')
        .onClick(() => this.removeCity(getCityKey(item.city)))
      }
      Column({ space: 5 }) {
        Text(item.city.name)
          .fontSize(19).fontWeight(FontWeight.Bold).fontColor('#0F0026')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.differenceHours > 0) {
          if (item.differenceHours === 1) {
            Text($r('app.string.hour_ahead', `${item.differenceHours}`))
              .fontSize(13).fontColor('#675A79')
          } else {
            Text($r('app.string.hours_ahead', `${item.differenceHours}`))
              .fontSize(13).fontColor('#675A79')
          }
        } else if (item.differenceHours < 0) {
          if (item.differenceHours === -1) {
            Text($r('app.string.hour_behind', `${-item.differenceHours}`))
              .fontSize(13).fontColor('#675A79')
          } else {
            Text($r('app.string.hours_behind', `${-item.differenceHours}`))
              .fontSize(13).fontColor('#675A79')
          }
        } else {
          Text($r('app.string.same_time')).fontSize(13).fontColor('#675A79')
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      TextClock({ timeZoneOffset: -item.offsetHours })
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#0F0026')
    }
    .width('100%').height(78).padding({ left: 16, right: 16 })
    .borderRadius(18).backgroundColor('#FFFFFF')
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        Column({ space: 8 }) {
          Text($r('app.string.local_time'))
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#00C9E5')
          TextClock()
            .fontSize(48).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Text(this.convertedDate)
            .fontSize(16).fontColor('#F8F3FF')
          Text(this.timeZone.substring(this.timeZone.lastIndexOf('/') + 1).split('_').join(' '))
            .fontSize(14).fontColor('#D8CBEA')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .width('100%').height(192)
        .padding(24)
        .borderRadius(26)
        .backgroundColor('#0F0026')
        .margin({ bottom: 22 })

        Row() {
          Text($r('app.string.world_clocks'))
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#0F0026')
          Blank()
          Button(this.isEdit ? $r('app.string.cancel') : $r('app.string.edit'))
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#6024B5')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.cityList.length === 0) {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.empty_edit') })
              } else {
                this.isEdit = !this.isEdit
              }
            })
        }
        .width('100%').margin({ bottom: 12 })

        if (this.cityList.length === 0) {
          Column({ space: 8 }) {
            Text($r('app.string.no_cities'))
              .fontSize(20).fontWeight(FontWeight.Medium).fontColor('#0F0026')
            Text($r('app.string.no_cities_hint'))
              .fontSize(15).fontColor('#675A79').textAlign(TextAlign.Center)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1).width('100%')
        } else {
          List({ scroller: this.scroller }) {
            ForEach(this.cityClocks, (item: CityClock) => {
              ListItem() {
                this.CityRow(item)
              }
              .margin({ bottom: 10 })
            }, (item: CityClock) => getCityKey(item.city))
              .onMove((from: number, to: number) => this.moveCity(from, to))
          }
          .layoutWeight(1).width('100%')
        }

        Button($r('app.string.add_city'))
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          .width('100%').height(54)
          .borderRadius(17).backgroundColor('#6024B5')
          .margin({ top: 12 })
          .onClick(() => this.addCity())
      }
      .width('100%').height('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 20 })
      .backgroundColor('#F8F3FF')
    }
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
    .title($r('app.string.clock'))
    .navDestination(this.PagesMap)
    .hideBackButton(true)
    .backgroundColor('#F8F3FF')
  }
}
