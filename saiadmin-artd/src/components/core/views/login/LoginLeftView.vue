<!-- 登录、注册、忘记密码左侧背景 -->
<template>
  <div class="login-left-view">
    <div class="logo">
      <ArtLogo class="icon" size="46" />
      <h1 class="title">{{ AppConfig.systemInfo.name }}</h1>
    </div>

    <div class="brand-hero">
      <div class="hero-card">
        <div class="hero-card__halo"></div>
        <div class="hero-card__pulse hero-card__pulse--one"></div>
        <div class="hero-card__pulse hero-card__pulse--two"></div>
        <img :src="brandLogo" alt="HelpSupport" class="brand-hero__logo" />
        <div class="support-badge support-badge--heart">
          <ArtSvgIcon icon="ri:heart-pulse-line" />
        </div>
        <div class="support-badge support-badge--shield">
          <ArtSvgIcon icon="ri:shield-check-line" />
        </div>
      </div>

      <div class="care-panel care-panel--daily">
        <span></span>
        <strong></strong>
        <i></i>
      </div>

      <div class="care-panel care-panel--message">
        <span></span>
        <strong></strong>
        <i></i>
      </div>
    </div>

    <div class="text-wrap">
      <h1> {{ $t('login.leftView.title') }} </h1>
      <p> {{ $t('login.leftView.subTitle') }} </p>
    </div>

    <div class="soft-shapes" aria-hidden="true">
      <span class="shape shape--coral"></span>
      <span class="shape shape--blue"></span>
      <span class="shape shape--mint"></span>
      <span class="shape shape--ring"></span>
      <span class="shape shape--dot"></span>
    </div>
  </div>
</template>

<script setup lang="ts">
  import AppConfig from '@/config'
  import brandLogo from '@imgs/common/logo.png'

  // 定义 props
  defineProps<{
    hideContent?: boolean // 是否隐藏内容，只显示 logo
  }>()
</script>

<style lang="scss" scoped>
  .login-left-view {
    position: relative;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    width: 65vw;
    height: 100%;
    min-height: 720px;
    padding: 28px 32px 46px;
    overflow: hidden;
    background:
      radial-gradient(circle at 18% 16%, rgb(255 180 168 / 42%), transparent 30%),
      radial-gradient(circle at 88% 12%, rgb(164 195 204 / 34%), transparent 27%),
      linear-gradient(142deg, #fff8f5 0%, #f6f4f1 46%, #eef6f8 100%);

    .logo {
      position: relative;
      z-index: 4;
      display: flex;
      align-items: center;

      .title {
        margin-left: 10px;
        font-size: 20px;
        font-weight: 650;
        color: #303236;
        letter-spacing: 0;
      }
    }

    .brand-hero {
      position: relative;
      z-index: 3;
      display: grid;
      place-items: center;
      width: min(520px, 58vw);
      height: min(520px, 56vh);
      min-height: 390px;
      margin: auto auto 28px;
      animation: slideInLeft 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;
    }

    .hero-card {
      position: relative;
      display: grid;
      place-items: center;
      width: 284px;
      height: 284px;
      border: 1px solid rgb(255 255 255 / 76%);
      border-radius: 46px;
      background:
        linear-gradient(145deg, rgb(255 255 255 / 92%), rgb(255 246 242 / 76%)),
        radial-gradient(circle at 50% 0%, rgb(255 149 133 / 22%), transparent 56%);
      box-shadow:
        0 28px 70px rgb(103 68 54 / 14%),
        0 14px 34px rgb(255 149 133 / 16%);
      transform: rotate(-3deg);
    }

    .hero-card__halo {
      position: absolute;
      inset: -52px;
      z-index: -1;
      border: 1px solid rgb(255 149 133 / 18%);
      border-radius: 50%;
      background: radial-gradient(circle, rgb(255 180 168 / 18%), transparent 68%);
    }

    .hero-card__pulse {
      position: absolute;
      border-radius: 999px;
      background: rgb(255 149 133 / 12%);
      box-shadow: inset 0 0 0 1px rgb(255 149 133 / 14%);

      &--one {
        right: -42px;
        bottom: 42px;
        width: 92px;
        height: 92px;
      }

      &--two {
        top: 34px;
        left: -46px;
        width: 68px;
        height: 68px;
        background: rgb(164 195 204 / 22%);
        box-shadow: inset 0 0 0 1px rgb(164 195 204 / 20%);
      }
    }

    .brand-hero__logo {
      width: 178px;
      height: 178px;
      filter: drop-shadow(0 18px 28px rgb(109 71 62 / 15%));
      transform: rotate(3deg);
    }

    .support-badge {
      position: absolute;
      display: grid;
      place-items: center;
      width: 54px;
      height: 54px;
      font-size: 24px;
      color: #fff;
      border: 5px solid rgb(255 255 255 / 84%);
      border-radius: 18px;
      box-shadow: 0 16px 34px rgb(255 149 133 / 22%);

      &--heart {
        right: 24px;
        bottom: 28px;
        background: linear-gradient(135deg, #ff9585, #ff7e70);
      }

      &--shield {
        top: 24px;
        left: 28px;
        background: linear-gradient(135deg, #a4c3cc, #7faebc);
      }
    }

    .care-panel {
      position: absolute;
      display: grid;
      gap: 10px;
      width: 176px;
      padding: 16px;
      border: 1px solid rgb(255 255 255 / 70%);
      border-radius: 22px;
      background: rgb(255 255 255 / 68%);
      box-shadow: 0 18px 46px rgb(95 72 62 / 10%);
      backdrop-filter: blur(18px);

      span,
      strong,
      i {
        display: block;
        height: 8px;
        border-radius: 999px;
      }

      span {
        width: 58%;
        background: rgb(255 149 133 / 44%);
      }

      strong {
        width: 86%;
        background: rgb(164 195 204 / 42%);
      }

      i {
        width: 42%;
        background: rgb(90 129 218 / 24%);
      }

      &--daily {
        top: 17%;
        right: 3%;
        transform: rotate(7deg);
      }

      &--message {
        bottom: 16%;
        left: 2%;
        transform: rotate(-8deg);
      }
    }

    .text-wrap {
      position: relative;
      z-index: 4;
      max-width: 640px;
      margin: 0 auto;
      width: 100%;
      text-align: center;
      animation: slideInLeft 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;

      h1 {
        font-size: 28px;
        font-weight: 700;
        line-height: 1.25;
        color: #303236 !important;
        letter-spacing: 0;
      }

      p {
        max-width: 560px;
        margin: 12px auto 0;
        font-size: 15px;
        line-height: 1.7;
        color: #7d828a !important;
      }
    }

    .soft-shapes {
      position: absolute;
      inset: 0;
      z-index: 1;
      pointer-events: none;

      .shape {
        position: absolute;
        display: block;
        opacity: 0.74;

        &--coral {
          top: -120px;
          right: -98px;
          width: 360px;
          height: 360px;
          border-radius: 50%;
          background: rgb(255 149 133 / 16%);
        }

        &--blue {
          bottom: 6%;
          left: 8%;
          width: 118px;
          height: 118px;
          border-radius: 36px;
          background: rgb(90 129 218 / 10%);
          transform: rotate(-18deg);
        }

        &--mint {
          top: 25%;
          left: 9%;
          width: 66px;
          height: 66px;
          border-radius: 24px;
          background: rgb(164 195 204 / 18%);
          transform: rotate(19deg);
        }

        &--ring {
          right: 12%;
          bottom: 14%;
          width: 96px;
          height: 96px;
          border: 2px solid rgb(255 149 133 / 14%);
          border-radius: 999px;
        }

        &--dot {
          top: 14%;
          left: 19%;
          width: 16px;
          height: 16px;
          border-radius: 50%;
          background: #ffb4a8;
          box-shadow:
            48vw 7vh 0 rgb(164 195 204 / 48%),
            26vw 64vh 0 rgb(255 149 133 / 34%),
            41vw 43vh 0 rgb(90 129 218 / 20%);
        }
      }
    }

    @keyframes slideInLeft {
      from {
        opacity: 0;
        transform: translateX(-30px);
      }

      to {
        opacity: 1;
        transform: translateX(0);
      }
    }

    @media only screen and (width <= 1600px) {
      width: 60vw;
      min-height: 660px;

      .brand-hero {
        width: min(460px, 54vw);
        height: min(460px, 54vh);
      }

      .hero-card {
        width: 250px;
        height: 250px;
        border-radius: 40px;
      }

      .brand-hero__logo {
        width: 156px;
        height: 156px;
      }

      .care-panel {
        width: 154px;
      }

      .text-wrap {
        h1 {
          font-size: 24px;
        }
      }
    }

    @media only screen and (width <= 1180px) {
      width: auto;
      height: auto;
      padding: 0;
      // 隐藏背景和其他内容，只保留 logo
      background: transparent;

      .brand-hero,
      .text-wrap,
      .soft-shapes {
        display: none;
      }

      .logo {
        display: none;
      }
    }
  }

  // 暗色主题
  .dark .login-left-view {
    background:
      radial-gradient(circle at 20% 18%, rgb(255 180 168 / 12%), transparent 30%),
      radial-gradient(circle at 88% 12%, rgb(164 195 204 / 14%), transparent 27%),
      linear-gradient(142deg, #171512 0%, #15181b 48%, #111c20 100%);

    .logo .title,
    .text-wrap h1 {
      color: #f7f7fa !important;
    }

    .text-wrap p {
      color: #a5a9b0 !important;
    }

    .hero-card {
      border-color: rgb(255 255 255 / 12%);
      background:
        linear-gradient(145deg, rgb(38 35 33 / 86%), rgb(29 27 27 / 72%)),
        radial-gradient(circle at 50% 0%, rgb(255 149 133 / 18%), transparent 56%);
      box-shadow:
        0 28px 70px rgb(0 0 0 / 32%),
        0 14px 34px rgb(255 149 133 / 10%);
    }

    .care-panel {
      border-color: rgb(255 255 255 / 10%);
      background: rgb(34 36 38 / 58%);
      box-shadow: 0 18px 46px rgb(0 0 0 / 20%);
    }

    @media only screen and (width <= 1180px) {
      background: transparent;
    }
  }
</style>
