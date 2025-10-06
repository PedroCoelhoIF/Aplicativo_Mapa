# Aplicativo Mapa 🗺️
 Aplicação Flutter de mapas interativos com rastreamento em tempo real, busca de endereços e interface moderna.

![Demonstração APP Mapa](https://github.com/PedroCoelhoIF/Aplicativo_Mapa/blob/main/assets/demo/demo-app-mapa.gif?raw=true)

## Sobre o Projeto:
Aplicação mobile desenvolvida em Flutter que oferece funcionalidades completas de mapeamento, incluindo:

 - Rastreamento em tempo real da localização do usuário
 - Busca de endereços com autocompletar usando Nominatim API
 - Marcadores personalizados no mapa
 - Controles de zoom intuitivos

## 🏗️ Arquitetura
O projeto segue o padrão MVVM (Model-View-ViewModel) para melhor organização e manutenibilidade:

```
lib/
├── main.dart                      # Ponto de entrada da aplicação
├── models/
│   └── location_model.dart        # Modelo de dados de localização
├── services/
│   └── location_service.dart      # Serviço de GPS e rastreamento
├── viewmodels/
│   └── location_viewmodel.dart    # Lógica de negócio e estado
└── views/
    └── map_view.dart              # Interface do usuário
```
### Responsabilidades:
  - Model: Estruturas de dados simples (LocationModel)
  - Service: Comunicação com APIs nativas (Geolocator)
  - ViewModel: Gerenciamento de estado e lógica de negócio
  - View: Renderização da UI e interação com usuário

## 🤝 Contribuindo
Contribuições são bem-vindas! Sinta-se à vontade para:
 - Fazer um fork do projeto
 - Criar uma branch para sua feature (git checkout -b feature/NovaFeature)
 - Commitar suas mudanças (git commit -m 'Add some NovaFeature')
 - Push para a branch (git push origin feature/NovaFeature)
 - Abrir um Pull Request
