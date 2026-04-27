import { common } from '@kit.AbilityKit';
import Recipe, { RecipeCategory } from '../../model/Recipe';
import RecipeRepository from '../../service/RecipeRepository';
import { allCategories, categoryLabel, sortedCategories } from '../../util/CategoryUtil';

interface CategoryGroup {
  category: RecipeCategory;
  recipes: Recipe[];
}

type CategoryFilter = RecipeCategory | 'all';

@Component
export struct RecipesPageDestination {
  @State private allRecipes: Recipe[] = [];
  @State private groups: CategoryGroup[] = [];
  @State private flatResults: Recipe[] = [];
  @State private isLoading: boolean = true;
  @State private query: string = '';
  @State private selectedCategory: CategoryFilter = 'all';
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.loadRecipes();
  }

  private async loadRecipes(): Promise<void> {
    if (!this.context) {
      this.isLoading = false;
      return;
    }
    const all = await RecipeRepository.getInstance().loadAll(this.context);
    this.allRecipes = all;
    this.applyFilters();
    this.isLoading = false;
  }

  private applyFilters(): void {
    const q = this.query.trim().toLowerCase();
    const cat = this.selectedCategory;

    let filtered: Recipe[] = this.allRecipes;
    if (cat !== 'all') {
      filtered = filtered.filter(r => r.category === cat);
    }
    if (q.length > 0) {
      filtered = filtered.filter(r =>
        r.name.toLowerCase().includes(q) ||
        r.ingredients.some(i => i.name.toLowerCase().includes(q))
      );
    }

    if (q.length === 0 && cat === 'all') {
      // Grouped view
      const map = new Map<RecipeCategory, Recipe[]>();
      filtered.forEach(r => {
        const arr = map.get(r.category) ?? [];
        arr.push(r);
        map.set(r.category, arr);
      });
      const ordered = sortedCategories(new Set(map.keys()));
      this.groups = ordered.map(c => {
        const group: CategoryGroup = { category: c, recipes: map.get(c) ?? [] };
        return group;
      });
      this.flatResults = [];
    } else {
      // Flat filtered view
      this.groups = [];
      this.flatResults = filtered;
    }
  }

  private onQueryChange(value: string): void {
    this.query = value;
    this.applyFilters();
  }

  private selectCategory(cat: CategoryFilter): void {
    this.selectedCategory = cat;
    this.applyFilters();
  }

  private clearSearch(): void {
    this.query = '';
    this.selectedCategory = 'all';
    this.applyFilters();
  }

  private isFiltered(): boolean {
    return this.query.trim().length > 0 || this.selectedCategory !== 'all';
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor($r('app.color.text_primary'))
            .margin({ right: 8 })
            .onClick(() => this.navPathStack.pop())
          Text($r('app.string.nav_recipes'))
            .fontSize(20)
            .fontWeight(900)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .padding(12)

        this.buildSearchBar()
        this.buildCategoryChips()

        if (this.isLoading) {
          Text($r('app.string.msg_loading'))
            .fontColor($r('app.color.text_secondary'))
            .margin(16)
        } else if (this.isFiltered()) {
          if (this.flatResults.length === 0) {
            Text($r('app.string.msg_no_results'))
              .fontColor($r('app.color.text_secondary'))
              .fontSize(13)
              .margin(16)
          } else {
            List({ space: 4 }) {
              ForEach(this.flatResults, (recipe: Recipe) => {
                ListItem() {
                  this.buildRow(recipe);
                }
                .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
              }, (recipe: Recipe) => recipe.id)
            }
            .width('100%')
            .layoutWeight(1)
          }
        } else {
          List({ space: 6 }) {
            ForEach(this.groups, (group: CategoryGroup) => {
              ListItemGroup({ header: this.buildHeader(group.category) }) {
                ForEach(group.recipes, (recipe: Recipe) => {
                  ListItem() {
                    this.buildRow(recipe);
                  }
                  .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
                }, (recipe: Recipe) => recipe.id)
              }
            }, (group: CategoryGroup) => group.category)
          }
          .sticky(StickyStyle.Header)
          .width('100%')
          .layoutWeight(1)
        }
      }
      .backgroundColor($r('app.color.background_primary'))
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

  @Builder
  private buildSearchBar() {
    Row({ space: 6 }) {
      TextInput({ placeholder: $r('app.string.hint_search'), text: this.query })
        .fontSize(12)
        .height(32)
        .layoutWeight(1)
        .backgroundColor($r('app.color.surface_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .fontColor($r('app.color.text_on_surface'))
        .borderRadius(16)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => this.onQueryChange(value))
      if (this.isFiltered()) {
        Text($r('app.string.btn_clear'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 6 })
          .onClick(() => this.clearSearch())
      }
    }
    .width('92%')
    .padding({ bottom: 6 })
  }

  @Builder
  private buildCategoryChips() {
    Scroll() {
      Row({ space: 6 }) {
        this.chip('all', $r('app.string.category_all'))
        ForEach(allCategories(), (c: RecipeCategory) => {
          this.chip(c, categoryLabel(c))
        }, (c: RecipeCategory) => c)
      }
      .padding({ left: 12, right: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  private chip(value: CategoryFilter, label: ResourceStr) {
    Text(label)
      .fontSize(11)
      .fontColor(this.selectedCategory === value
        ? $r('app.color.text_on_surface')
        : $r('app.color.text_secondary'))
      .backgroundColor(this.selectedCategory === value
        ? $r('app.color.surface_primary')
        : Color.Transparent)
      .border({
        width: 1,
        color: $r('app.color.text_secondary'),
        radius: 12
      })
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .onClick(() => this.selectCategory(value))
  }

  @Builder
  private buildHeader(category: RecipeCategory) {
    Row() {
      Text(categoryLabel(category))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildRow(recipe: Recipe) {
    Row({ space: 10 }) {
      Image($rawfile(recipe.imageSource))
        .width(44)
        .height(44)
        .borderRadius(22)
        .objectFit(ImageFit.Cover)
      Column({ space: 2 }) {
        Text(recipe.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text(`${recipe.durationMin} `)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text($r('app.string.label_minutes'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text('·')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text(`${recipe.servings} `)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text($r('app.string.label_servings'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
  }
}
