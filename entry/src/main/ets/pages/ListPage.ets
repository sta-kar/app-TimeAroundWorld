import { City, getCityKey, getOffsetHours, supportedSystemTimezone } from '../Data/DataSource'

@Component
export struct ListPage {
  private pathStack: NavPathStack = new NavPathStack()
  @StorageLink('cityList') cityList: City[] = []
  @State private visibleCities: City[] = supportedSystemTimezone
  @State private query: string = ''
  @State private selectedIndex: number = 0
  @State private currentTime: number = Date.now()
  private scroller: Scroller = new Scroller()
  private intervalId: number = 0
  private alphabets: string[] =
    ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
      'X', 'Y', 'Z']

  aboutToAppear(): void {
    if (this.intervalId === 0) {
      this.intervalId = setInterval(() => {
        this.currentTime = Date.now()
      }, 60000)
    }
  }

  aboutToDisappear(): void {
    if (this.intervalId !== 0) {
      clearInterval(this.intervalId)
      this.intervalId = 0
    }
  }

  private search(value: string): void {
    this.query = value
    const normalized = value.trim().toLowerCase()
    this.visibleCities = normalized.length === 0 ? supportedSystemTimezone :
      supportedSystemTimezone.filter((city: City) => city.name.toLowerCase().includes(normalized))
  }

  private isSelected(city: City): boolean {
    return this.cityList.some((selected: City) => getCityKey(selected) === getCityKey(city))
  }

  private select(city: City): void {
    if (this.isSelected(city)) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.already_added') })
      } catch (error) {
        console.error(`Could not show city status: ${error}`)
      }
      return
    }
    try {
      this.pathStack.pop(city)
    } catch (error) {
      console.error(`Could not select city: ${error}`)
    }
  }

  private scrollToLetter(letter: string): void {
    const index = supportedSystemTimezone.findIndex((city: City) => city.headerWord === letter)
    if (index >= 0) {
      this.scroller.scrollToIndex(index)
    }
  }

  build() {
    NavDestination() {
      Column() {
        Search({ value: this.query, placeholder: $r('app.string.search') })
          .width('100%').height(50)
          .borderRadius(15).backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })
          .onChange((value: string) => this.search(value))
          .onSubmit((value: string) => this.search(value))

        if (this.visibleCities.length === 0) {
          Column() {
            Text($r('app.string.no_results'))
              .fontSize(18).fontWeight(FontWeight.Medium).fontColor('#675A79')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1).width('100%')
        } else {
          Stack({ alignContent: Alignment.End }) {
            List({ scroller: this.scroller }) {
              ForEach(this.visibleCities, (item: City, index: number) => {
                ListItem() {
                  Column() {
                    if (this.query.trim().length === 0 &&
                      (index === 0 || item.headerWord !== this.visibleCities[index - 1].headerWord)) {
                      Text(item.headerWord)
                        .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#6024B5')
                        .width('100%').margin({ left: 6, top: 14, bottom: 7 })
                    }
                    Row({ space: 10 }) {
                      Column({ space: 5 }) {
                        Text(item.name)
                          .fontSize(18).fontWeight(FontWeight.Medium).fontColor('#0F0026')
                          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(this.formatOffset(getOffsetHours(item.timezone, this.currentTime)))
                          .fontSize(13).fontColor('#675A79')
                      }
                      .alignItems(HorizontalAlign.Start).layoutWeight(1)
                      if (this.isSelected(item)) {
                        Text('✓')
                          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#6024B5')
                      }
                    }
                    .width('100%').height(74)
                    .padding({ left: 16, right: 16 })
                    .borderRadius(17).backgroundColor('#FFFFFF')
                  }
                }
                .margin({ bottom: 8 })
                .onClick(() => this.select(item))
              }, (item: City) => getCityKey(item))
            }
            .width('100%').height('100%')
            .padding({ right: this.query.trim().length === 0 ? 30 : 0 })
            .onScrollIndex((start: number) => {
              if (this.query.trim().length === 0 && start >= 0 && start < this.visibleCities.length) {
                this.selectedIndex = this.alphabets.indexOf(this.visibleCities[start].headerWord)
              }
            })

            if (this.query.trim().length === 0) {
              AlphabetIndexer({ arrayValue: this.alphabets, selected: this.selectedIndex })
                .width(24)
                .color('#675A79').selectedColor('#6024B5')
                .onSelect((index: number) => this.scrollToLetter(this.alphabets[index]))
            }
          }
          .layoutWeight(1).width('100%')
        }
      }
      .width('100%').height('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor('#F8F3FF')
    }
    .title($r('app.string.cities'))
    .backgroundColor('#F8F3FF')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }

  private formatOffset(offsetHours: number): string {
    return `UTC${offsetHours >= 0 ? '+' : ''}${offsetHours}`
  }
}
