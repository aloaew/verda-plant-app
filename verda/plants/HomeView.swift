import SwiftUI
import Combine
import Foundation


extension Color {
    static let primaryGreen = Color(red: 0.2, green: 0.6, blue: 0.4)
    static let lightGreen = Color(red: 0.8, green: 0.95, blue: 0.85)
    static let darkGreen = Color(red: 0.1, green: 0.4, blue: 0.3)
    static let accentYellow = Color(red: 0.95, green: 0.85, blue: 0.3)
}


struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let link: String
    let pubDate: String
    let imageUrl: String?
}


class NewsViewModel: NSObject, ObservableObject, XMLParserDelegate {
    @Published var newsItems: [NewsItem] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentImageUrl: String?
    
    func fetchNews() {
        guard let url = URL(string: "https://www.botanichka.ru/feed/") else { return }
        guard let parser = XMLParser(contentsOf: url) else { return }
        
        newsItems.removeAll()
        parser.delegate = self
        parser.parse()
    }
    
    // MARK: - XMLParser Delegate Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item" {
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentImageUrl = nil
        } else if elementName == "enclosure", let url = attributeDict["url"] {
            currentImageUrl = url
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string.trimmingCharacters(in: .whitespacesAndNewlines)
        case "link":
            currentLink += string.trimmingCharacters(in: .whitespacesAndNewlines)
        case "pubDate":
            currentPubDate += string.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            let newsItem = NewsItem(title: currentTitle, link: currentLink, pubDate: currentPubDate, imageUrl: currentImageUrl)
            DispatchQueue.main.async {
                if self.newsItems.count < 10 { 
                    self.newsItems.append(newsItem)
                }
            }
        }
    }
}


struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let plants: [Plant]
}


struct Plant: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let imageUrl: String
    let facts: [String]
    let recommendations: [String]
}


struct CategoryButton: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.primaryGreen)
                .clipShape(Circle())
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.lightGreen.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 1)
        )
    }
}


struct NewsCard: View {
    let item: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .overlay(
                                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                            )
                    } else if phase.error != nil {
                        Color.gray.opacity(0.3)
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    } else {
                        ProgressView()
                            .frame(height: 180)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(item.pubDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 4)
    }
}


struct PlantDetailView: View {
    let plant: Plant
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Изображение растения
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: plant.imageUrl)) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                        } else if phase.error != nil {
                            Color.gray.opacity(0.3)
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.white)
                                        .font(.largeTitle)
                                )
                        } else {
                            ProgressView()
                                .frame(height: 250)
                        }
                    }
                    
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 250)
                    
                    Text(plant.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.top)
                
               
                VStack(alignment: .leading, spacing: 8) {
                    Text("Описание")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primaryGreen)
                    
                    Text(plant.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.accentYellow)
                        Text("Интересные факты")
                            .font(.title2)
                            .bold()
                    }
                    .foregroundColor(.primaryGreen)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(plant.facts, id: \.self) { fact in
                            HStack(alignment: .top) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.primaryGreen)
                                    .padding(.top, 3)
                                Text(fact)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.lightGreen.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Рекомендации по уходу
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.primaryGreen)
                        Text("Рекомендации по уходу")
                            .font(.title2)
                            .bold()
                    }
                    .foregroundColor(.primaryGreen)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(plant.recommendations, id: \.self) { rec in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.primaryGreen)
                                    .padding(.top, 3)
                                Text(rec)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.lightGreen.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
    }
}


struct CategoryView: View {
    let category: Category
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
               
                HStack {
                    Image(systemName: category.icon)
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.primaryGreen)
                        .clipShape(Circle())
                    
                    Text(category.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primaryGreen)
                    
                    Spacer()
                }
                .padding()
                .background(Color.lightGreen.opacity(0.3))
                
               
                LazyVStack(spacing: 16) {
                    ForEach(category.plants) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            PlantCard(plant: plant)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct PlantCard: View {
    let plant: Plant
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: plant.imageUrl)) { phase in
                if let image = phase.image {
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if phase.error != nil {
                    Color.gray.opacity(0.3)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.white)
                        )
                } else {
                    ProgressView()
                        .frame(width: 80, height: 80)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(plant.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// Основное представление
struct HomeView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var searchText = ""
    
    let categories: [Category] = [
        Category(name: "Листовая зелень", icon: "leaf.fill", plants: [
            Plant(name: "Кресс-салат",
                  description: "Быстрорастущая зелень с острым, горчичным вкусом.",
                  imageUrl: "https://tse2.mm.bing.net/th?id=OIP.mVzjkHq6QT0HoqRyOy2lQgHaE8&pid=Api",
                  facts: ["Богат витаминами A, C и группы B", "Содержит горчичное эфирное масло, придающее ему специфический вкус"],
                  recommendations: ["Предпочитает прохладный климат (15–18°C)", "Регулярный полив, особенно в жаркую погоду"]),
            
            Plant(name: "Шпинат",
                  description: "Листовая зелень с мягким вкусом, популярная в салатах и горячих блюдах.",
                  imageUrl: "https://tse3.mm.bing.net/th?id=OIP.hRCG4WLULZUZXymOL7bx4QHaFA&pid=Api",
                  facts: ["Богат железом, магнием и антиоксидантами", "Полезен для здоровья сердца и сосудов"],
                  recommendations: ["Предпочитает плодородную, влажную почву", "Регулярный полив и тень в жаркую погоду"]),
            
            Plant(name: "Листовой салат",
                  description: "Популярная зелень с хрустящими листьями, используемая в салатах и бутербродах.",
                  imageUrl: "https://tse1.mm.bing.net/th?id=OIP.Pg9mhtSphdT6hi3l4GWd0AHaEK&pid=Api",
                  facts: ["Содержит клетчатку, полезную для пищеварения", "Богат витаминами A, C и группы B"],
                  recommendations: ["Предпочитает прохладный климат (15–20°C)", "Требует регулярного полива"]),
            
            Plant(name: "Мангольд",
                  description: "Листовая свекла с крупными листьями и толстыми черешками, богатая витаминами.",
                  imageUrl: "https://tse2.mm.bing.net/th?id=OIP.qI-QPQSOnCCTE6W24AmblwHaEK&pid=Api",
                  facts: ["Содержит много магния, калия и железа", "Обладает антиоксидантными свойствами"],
                  recommendations: ["Сеять с ранней весны до середины лета", "Требует солнечного места и регулярного полива"]),
            
            Plant(name: "Эндивий",
                  description: "Зелень с слегка горьковатым вкусом, популярная в средиземноморской кухне.",
                  imageUrl: "https://images.deal.by/342823316_w640_h640_semena-tsikoriya-i.jpg",
                  facts: ["Содержит витамины A, C и K", "Богат инулином, полезным для пищеварения"],
                  recommendations: ["Оптимальная температура роста 16–20°C", "Сеять весной или в конце лета"]),
            
            Plant(name: "Руккола",
                  description: "Пряная зелень с ореховым вкусом, используемая в салатах и пастах.",
                  imageUrl: "https://t4.ftcdn.net/jpg/00/71/24/91/360_F_71249162_HB7QnhuPMslnK2DGtonJNv4uyZnuFraN.jpg",
                  facts: ["Богата кальцием, железом и фитонцидами", "Содержит глюкозинолаты, которые способствуют детоксикации организма"],
                  recommendations: ["Скороспелая культура, урожай через 20–25 дней", "Требует регулярного полива, иначе листья становятся горькими"])
        ]),
        
        Category(name: "Ароматные травы", icon: "sparkles", plants: [
            Plant(name: "Базилик",
                  description: "Ароматная трава с пряным вкусом, широко используемая в кулинарии.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/-16/711/608/610/111/558/100071261154b0.jpg",
                  facts: ["Богат антиоксидантами и эфирными маслами", "Способствует пищеварению и укрепляет иммунитет"],
                  recommendations: ["Любит тепло и солнце", "Регулярный полив, но без переувлажнения"]),
            
            Plant(name: "Петрушка",
                  description: "Популярная трава с освежающим вкусом, богатая витаминами.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/911/418/469/925/153/2/100039284808b0.jpg",
                  facts: ["Содержит витамин C и железо", "Обладает мочегонным эффектом"],
                  recommendations: ["Растет в тени и на солнце", "Регулярный полив и рыхлая почва"]),
            
            Plant(name: "Кинза",
                  description: "Пряная трава с сильным ароматом, часто используемая в азиатской и кавказской кухне.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/-30/775/531/612/241/458/100030021870b0.jpg",
                  facts: ["Помогает пищеварению и выводит токсины", "Содержит много витамина K и антиоксидантов"],
                  recommendations: ["Любит солнечные места", "Полив умеренный, не переносит избыточную влагу"]),
            
            Plant(name: "Тимьян",
                  description: "Ароматная трава с пряным, слегка горьковатым вкусом.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big2/hlr-system/109/391/952/252/411/23/100028506091b2.jpg",
                  facts: ["Содержит эфирные масла, обладающие антисептическими свойствами", "Помогает при простуде и кашле"],
                  recommendations: ["Предпочитает солнечные, сухие места", "Редкий полив, устойчива к засухе"])
        ]),
        
        Category(name: "Микрозелень", icon: "drop.fill", plants: [
            Plant(name: "Микрозелень горчицы",
                  description: "Растет при низких температурах, быстрый рост за 3-5 дней. Обладает острым вкусом и используется в салатах и гарнирах.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big2/hlr-system/-90/173/991/151/746/100071681331b0.png",
                  facts: ["Богат витаминами A и C", "Растет в воде без почвы", "Стимулирует пищеварение", "Содержит антиоксиданты"],
                  recommendations: ["Полив 1 раз в 2 дня", "Теплый, солнечный свет", "Оптимальная температура 18-22°C"]),
            
            Plant(name: "Микрозелень редиса",
                  description: "Любит влажную почву, выращивается круглый год. Обладает острым, перечным вкусом и богата антиоксидантами.",
                  imageUrl: "https://cdn1.ozone.ru/s3/multimedia-e/6846555398.jpg",
                  facts: ["Содержит много железа", "Помогает укрепить иммунитет", "Улучшает кровообращение", "Богата калием и магнием"],
                  recommendations: ["Требует тени в жаркую погоду", "Регулярный полив", "Оптимальная температура 16-20°C"]),
            
            Plant(name: "Микрозелень гороха",
                  description: "Растет при низких температурах, быстрый рост за 3-5 дней. Имеет сладковатый вкус и хрустящую текстуру.",
                  imageUrl: "https://cdn1.ozone.ru/s3/multimedia-y/6059263198.jpg",
                  facts: ["Богат витаминами A и C", "Растет в воде без почвы", "Содержит растительный белок", "Улучшает работу кишечника"],
                  recommendations: ["Полив 1 раз в 2 дня", "Теплый, солнечный свет", "Оптимальная температура 15-20°C"]),
            
            Plant(name: "Микрозелень подсолнечника",
                  description: "Растет при низких температурах, быстрый рост за 3-5 дней. Имеет ореховый вкус и богата белками.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/-17/086/019/369/261/150/100060221637b0.jpg",
                  facts: ["Богат витаминами A и C", "Растет в воде без почвы", "Содержит большое количество клетчатки", "Поддерживает здоровье костей"],
                  recommendations: ["Полив 1 раз в 2 дня", "Теплый, солнечный свет", "Оптимальная температура 18-24°C"]),
            
            Plant(name: "Микрозелень брокколи",
                  description: "Растет при низких температурах, быстрый рост за 3-5 дней. Содержит большое количество сульфорафана, полезного для организма.",
                  imageUrl: "https://cdn1.ozone.ru/s3/multimedia-z/6092931011.jpg",
                  facts: ["Богат витаминами A и C", "Растет в воде без почвы", "Снижает уровень холестерина", "Обладает противовоспалительными свойствами"],
                  recommendations: ["Полив 1 раз в 2 дня", "Теплый, солнечный свет", "Оптимальная температура 18-22°C"]),
            
            Plant(name: "Микрозелень амаранта",
                  description: "Растет при низких температурах, быстрый рост за 3-5 дней. Обладает насыщенным цветом и легким ореховым вкусом.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big2/hlr-system/-16/711/704/710/111/557/100071261153b0.jpg",
                  facts: ["Богат витаминами A и C", "Растет в воде без почвы", "Содержит лизин – важную аминокислоту", "Полезен для сердечно-сосудистой системы"],
                  recommendations: ["Полив 1 раз в 2 дня", "Теплый, солнечный свет", "Оптимальная температура 16-22°C"])
        ]),
        
        Category(name: "Крестоцветные овощные культуры", icon: "flame.fill", plants: [
            Plant(name: "Капуста кале",
                  description: "Листовая капуста с насыщенным вкусом, устойчива к холоду, богата клетчаткой.",
                  imageUrl: "https://cdn1.ozone.ru/s3/multimedia-u/c600/6851236098.jpg",
                  facts: ["Содержит много витамина K", "Богата антиоксидантами", "Улучшает пищеварение", "Поддерживает здоровье кожи"],
                  recommendations: ["Полив 2-3 раза в неделю", "Растет при температуре 10-20°C", "Предпочитает солнечное место"]),
            
            Plant(name: "Листовая капуста",
                  description: "Азиатские сорта капусты с мягкими листьями, богаты витаминами и минералами.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/103/051/434/911/251/827/100045463176b0.jpg",
                  facts: ["Содержит витамин C и кальций", "Легко усваивается", "Поддерживает здоровье костей", "Помогает снижать воспаление"],
                  recommendations: ["Полив 2 раза в неделю", "Растет при температуре 15-22°C", "Предпочитает полутень"]),
            
            Plant(name: "Брокколи",
                  description: "Популярный крестоцветный овощ, богат клетчаткой и антиоксидантами, используется в кулинарии.",
                  imageUrl: "https://main-cdn.sbermegamarket.ru/big1/hlr-system/989/004/380/104/133/9/100029280376b0.jpg",
                  facts: ["Содержит сульфорафан", "Улучшает иммунитет", "Поддерживает здоровье сердца", "Богат витаминами B и C"],
                  recommendations: ["Полив 2 раза в неделю", "Растет при температуре 18-24°C", "Предпочитает солнечный свет"]),
            
            Plant(name: "Мизуна",
                  description: "Японская зелень с мягким, слегка перечным вкусом, используется в салатах и гарнирах.",
                  imageUrl: "https://cdn.metro-cc.ru/ru/ru_pim_329041005001_01.png",
                  facts: ["Содержит антиоксиданты", "Богата витаминами A и K", "Улучшает пищеварение", "Поддерживает здоровье глаз"],
                  recommendations: ["Полив 1-2 раза в неделю", "Растет при температуре 12-20°C", "Хорошо переносит тень"])
        ]),
        
        Category(name: "Луковичные и пряные растения", icon: "circle.hexagongrid.fill", plants: [
            Plant(name: "Зеленый лук",
                  description: "Листовой лук с мягким вкусом, богатый витаминами и минералами.",
                  imageUrl: "https://cdn.vseinstrumenti.ru/images/goods/sadovaya-tehnika-i-instrument/tovary-dlya-uhoda-za-rasteniyam/10926254/1200x800/149202440.jpg",
                  facts: ["Содержит витамин C, калий и фитонциды", "Укрепляет иммунитет и улучшает пищеварение"],
                  recommendations: ["Растет в прохладном и теплом климате", "Требует регулярного, но умеренного полива"]),
            
            Plant(name: "Шнитт-лук",
                  description: "Тонкий зеленый лук с нежным вкусом, используется в салатах и соусах.",
                  imageUrl: "https://klubsadprof.ru/upload/iblock/7a1/7dy7x02quyb04o276he0m3bwbbtznqr4.jpg",
                  facts: ["Богат витаминами A и C", "Содержит антиоксиданты, поддерживающие здоровье кожи"],
                  recommendations: ["Предпочитает солнечные места", "Регулярный полив, но без застоя воды"]),
            
            Plant(name: "Чеснок",
                  description: "Ароматные зеленые побеги чеснока с пикантным вкусом.",
                  imageUrl: "https://thumbs.dreamstime.com/b/%D0%B2%D1%81%D1%85%D0%BE%D0%B4%D1%8B-%D1%87%D0%B5%D1%81%D0%BD%D0%BE%D0%BA%D0%B0-%D0%BD%D0%B0-%D0%B1%D0%B5%D0%BB%D0%BE%D0%B9-%D0%BF%D1%80%D0%B5%D0%B4%D0%BF%D0%BE%D1%81%D1%8B%D0%BB%D0%BA%D0%B5-122251274.jpg",
                  facts: ["Обладает антисептическими и противовирусными свойствами", "Содержит сернистые соединения, полезные для сердца"],
                  recommendations: ["Любит солнечные места", "Полив умеренный, не переносит переувлажнение"]),
            
            Plant(name: "Фенхель",
                  description: "Пряное растение с анисовым ароматом, популярное в средиземноморской кухне.",
                  imageUrl: "https://www.semena-tut.ru/components/com_jshopping/files/img_products/full_fenhel-snegjnost-aelita.jpg",
                  facts: ["Содержит витамины A, C и кальций", "Улучшает пищеварение и снимает воспаления"],
                  recommendations: ["Предпочитает солнечные места", "Регулярный полив, но без застоя воды"])
        ])
    ]
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.map { category in
                let filteredPlants = category.plants.filter { plant in
                    plant.name.localizedCaseInsensitiveContains(searchText) ||
                    plant.description.localizedCaseInsensitiveContains(searchText)
                }
                return Category(name: category.name, icon: category.icon, plants: filteredPlants)
            }.filter { !$0.plants.isEmpty }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Поиск
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🌿 Категории растений")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primaryGreen)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(destination: CategoryView(category: category)) {
                                    CategoryButton(category: category)
                                }
                                .buttonStyle(PlainButtonStyle()) // Важно!
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Новости
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Новости о растениях")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "2E7D32"))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.fetchNews()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.newsItems) { item in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Изображение новости
                                    if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 200)
                                                    .clipped()
                                                    .overlay(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [.clear, .black.opacity(0.1)]),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                            } else if phase.error != nil {
                                                Color.gray.opacity(0.1)
                                                    .frame(height: 200)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.white)
                                                    )
                                            } else {
                                                ProgressView()
                                                    .frame(height: 200)
                                            }
                                        }
                                    }
                                    
                                    // Текст новости
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .padding(.top, 12)
                                        
                                        HStack {
                                            Text(item.pubDate)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("Читать далее →")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "4CAF50"))
                                        }
                                        .padding(.bottom, 12)
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .onTapGesture {
                                    if let url = URL(string: item.link) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.top)
            }
            .navigationTitle("Растения")
            .onAppear {
                viewModel.fetchNews()
            }
        }
    }
}

// Поисковая строка
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Поиск растений...", text: $text)
                    .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !text.isEmpty {
                Button("Отмена") {
                    text = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(.primaryGreen)
                .transition(.move(edge: .trailing))
                .animation(.default, value: text)
            }
        }
        .animation(.default, value: text)
    }
}

// Превью
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
