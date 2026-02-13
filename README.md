# 🌌 Black Hole Simulator: Apple Metal 4

Uma implementação de **Ray Marching** em tempo real baseada na métrica de Schwarzschild da Relatividade Geral. O simulador processa as geodésicas da luz ao redor de uma massa central, tratando cada fóton como uma partícula dinâmica sujeita à curvatura do espaço-tempo.

---
<img width="912" height="744" alt="image" src="https://github.com/user-attachments/assets/60de0a3f-ff8c-4921-8677-e17153bf483a" />

## 🛠 Arquitetura e Lógica

Diferente de renderizações estáticas, o projeto utiliza **Compute Shaders (GPGPU)** para resolver numericamente a trajetória da luz a 60 FPS.

### Física Simulada:

* **Lente Gravitacional:** Distorção extrema do plano de fundo baseada em um Skybox procedural.
* **Horizonte de Eventos:** Delimitação do ponto de não retorno via Raio de Schwarzschild ().
* **Disco de Acreção:** Simulação de plasma superaquecido utilizando turbulência e ruído procedural (*Value Noise*).
* **Beaming Relativístico:** Assimetria de brilho (Efeito Doppler) causada pela velocidade orbital da matéria.
* **Redshift Gravitacional:** Simulação da perda de energia da luz ao escapar do poço gravitacional.

---

## 📖 Documentação Técnica (Artigo)

Para uma análise profunda sobre a implementação das equações no Metal, o tratamento de performance e a matemática envolvida, confira o artigo completo:

👉 **[Dark Hole Simulation with Apple Metal (Medium)](https://medium.com/@nyeeldzn/dark-hole-simulation-with-apple-metal-a4ba70766577)**

---

## 💻 Tech Stack

| Componente | Especificação |
| --- | --- |
| **Linguagem** | Swift 5.10+ |
| **Graphics API** | Metal 4 |
| **Paradigma** | GPGPU / Compute Shaders |
| **Hardware** | Otimizado para Apple Silicon (M1/M2/M3) |
| **IDE** | Xcode 15+ |

---

## 🕹 Como Rodar

1. **Clone o repositório:**
```bash
git clone https://github.com/nyeeldzn/black-hole-simulation-with-metal.git

```

2. **Abra o projeto:**
Execute o arquivo `.xcodeproj` no Xcode.
3. **Build & Run:**
Selecione **My Mac** como destino e use `Cmd + R`.
4. **Interação:**
Ajuste as constantes físicas (Gravidade, Massa, Densidade) em tempo real através dos sliders na interface lateral.
