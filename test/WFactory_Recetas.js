// const assert = require("assert");
const Web3 = require('web3');
const web3 = new Web3();
const BigNumber = require('bignumber.js');
const ethers = require('ethers');
const EthCrypto = require('eth-crypto');
const WFactoryHelper = require('../wfactory-helper');

const recetaFn = ({ description, patient, doctor,
pharmacy, amount, tax }) => {
  if (!doctor) {
    doctor = [];
  }
  if (!patient) {
    patient = [];
  }
  if (!pharmacy) {
    pharmacy = [];
  }
  let rlpContent = [];
  rlpContent = [
    (description),
    [...doctor],
    [...patient],
    [...pharmacy],
    amount,
    tax
  ];
  return rlpContent;
}


contract('WTemplate - RecetaModel', (accounts) => {
  let owner;
  let template = null;
  let templAddress = '';
  let modelContract;
  let factoryContract;
  let approvalsContract;
  let approvalExtensionId;
  let eventRegistry;
  let WFactoryContract = artifacts.require('WFactory');
  let ExtensionEventRegistry = artifacts.require('ExtensionEventRegistry');
  let Approvals = artifacts.require('Approvals');
  let TestDocumentModelContract = artifacts.require('RecetaModel');
  let WTemplateContract = artifacts.require('WTemplate');
  let wf = new WFactoryHelper();

  // States
  wf.createStates([
    'NONE',
    'PRESCRIPTION_SENT',
    'RX_REQUEST',
    'RX_ACCEPT',
    'RX_REJECT',
    'PATIENT_PAYMENT_SENT',
    'PAYMENT_RCV',
    'COMPLETED'
  ]);

  //  Actors
  wf.createActors(['DR','PATIENT', 'RX']);

  // Steps
  wf.createStep({
    currentActor: wf.getActor('DR'),
    current: wf.getState('NONE'), // none
    next: wf.getState('PRESCRIPTION_SENT'), // created
    mappingType: 0, // init
  });
  wf.createStep({
    currentActor: wf.getActor('PATIENT'),
    current: wf.getState('PRESCRIPTION_SENT'), // created
    next: wf.getState('RX_REQUEST'), // accepted
    mappingType: 2, // status
    stepValidations: [wf.getState('PRESCRIPTION_SENT')],
  });
  wf.createStep({
    currentActor: wf.getActor('RX'),
    current: wf.getState('RX_REQUEST'),
    next: wf.getState('RX_ACCEPT'), 
    mappingType: 2,
    forkId: wf.getState('RX_REJECT'),
    stepValidations: [wf.getState('RX_REQUEST')],
    // recipientValidations: [accounts[2]],
  });
  wf.createStep({
    currentActor: wf.getActor('RX'),
    current: wf.getState('RX_REQUEST'),
    next: wf.getState('RX_REJECT'),
    mappingType: 2,
    // forkId: wf.getState('MULTI_SIGNERS'),
    stepValidations: [wf.getState('RX_REQUEST')],
    // recipientValidations: [...accounts],
  });
  wf.createStep({
    currentActor: wf.getActor('PATIENT'),
    current: wf.getState('RX_ACCEPT'),
    next: wf.getState('PATIENT_PAYMENT_SENT'),
    mappingType: 2,
    // forkId: wf.getState('MULTI_SIGNERS'),
    stepValidations: [wf.getState('RX_ACCEPT')],
    // recipientValidations: [...accounts],
  });
  wf.createStep({
    currentActor: wf.getActor('RX'),
    current: wf.getState('PATIENT_PAYMENT_SENT'),
    next: wf.getState('PAYMENT_RCV'),
    mappingType: 2,
    // forkId: wf.getState('MULTI_SIGNERS'),
    stepValidations: [wf.getState('PATIENT_PAYMENT_SENT')],
    // recipientValidations: [...accounts],
  });
  wf.createStep({
    currentActor: wf.getActor('PATIENT'),
    current: wf.getState('PAYMENT_RCV'),
    next: wf.getState('COMPLETED'),
    mappingType: 2,
    // forkId: wf.getState('MULTI_SIGNERS'),
    stepValidations: [wf.getState('PAYMENT_RCV')],
    // recipientValidations: [...accounts],
  });
  
  let rxAddress;
  let doctorAddress;
  let userAddr;
  contract('#wfactory', () => {
    before(async () => {
      // event registry
      eventRegistry = await ExtensionEventRegistry.new();
      approvalsContract = await Approvals.new({ from: accounts[0] });
      // create model contract
      modelContract = await TestDocumentModelContract.new(
        eventRegistry.address
      );
      owner = accounts[0];
      userAddr = accounts[1];
      doctorAddress = accounts[2];
      recipientAddr = accounts[2];
      rxAddress = accounts[3];

      await approvalsContract.addACL(userAddr, 0, {
        from: owner,
      });
      await approvalsContract.addACL(userAddr, 1, {
        from: owner,
      });

      // Create approval check
      const logs = await approvalsContract.add(
        userAddr,
        [userAddr, doctorAddress],
        [515, 300],
        2,
        {
          from: userAddr,
        }
      );

      const id = logs.receipt.logs[0].args.id;

      // Add Approval as extension
      const regLog = await eventRegistry.add(
        'approvals',
        approvalsContract.address,
        id
      );

      approvalExtensionId = regLog.receipt.logs[0].args.id;
      console.log(approvalExtensionId);
    });

    describe('create wtemplate', () => {
      it('should generate workflow template', async () => {
        factoryContract = await WFactoryContract.new();
        const tx = await factoryContract.payWorkflowTemplate(modelContract.address, {
          value: 0.002*1e18
        });
        templAddress = tx.logs[0].args[0];
        console.log(`templ: ${templAddress}`)
        template = await WTemplateContract.at(templAddress);
        await template.createWF(
          wf.createWFPayload(
            wf.getSteps(), [
            [wf.getActor('DR'), 
            wf.getState('NONE'), 
            wf.getState('PRESCRIPTION_SENT')],
            [
              wf.getActor('PATIENT'),
              wf.getState('PRESCRIPTION_SENT'),
              wf.getState('RX_REQUEST'),
            ],
            [
              wf.getActor('RX'),
              wf.getState('RX_REQUEST'),
              wf.getState('RX_ACCEPT'),
            ],
            [
              wf.getActor('RX'),
              wf.getState('RX_REQUEST'),
              wf.getState('RX_REJECT'),
            ],
            [
              wf.getActor('PATIENT'),
              wf.getState('RX_ACCEPT'),
              wf.getState('PATIENT_PAYMENT_SENT'),
            ],
            [
              wf.getActor('RX'),
              wf.getState('PATIENT_PAYMENT_SENT'),
              wf.getState('PAYMENT_RCV'),
            ],
            [
              wf.getActor('PATIENT'),
              wf.getState('PAYMENT_RCV'),
              wf.getState('COMPLETED'),
            ],
          ])
        );
      
        //  await contract.addACL(owner, 0); // add owner as admin
        await template.addACL(owner); // add recipient

        // create license
        const lic = await template.createUserAccess(
          web3.utils.sha3('Panama Protege 2020'),
          new Date(2021, 2, 2).getTime() / 1000,
          'Licencia para MITRADEL'
        );
        const lic2 = await template.createUserAccess(
          web3.utils.sha3('Panama Protege 2020 #2'),
          new Date(2021, 2, 2).getTime() / 1000,
          'Licencia para usuario'
        );

        const lic3 = await template.createUserAccess(
          web3.utils.sha3('Panama Protege 2020 #3'),
          new Date(2021, 2, 2).getTime() / 1000,
          'Licencia para cliente'
        );

        let ok = await template.addIdentity(
          userAddr,
          `did:ethr:${userAddr}`,
          web3.utils.sha3('Panama Protege 2020'),
          { from: userAddr }
        );
        ok = await template.addIdentity(
          doctorAddress,
          `did:ethr:${doctorAddress}`,
          web3.utils.sha3('Panama Protege 2020 #2'),
          { from: doctorAddress }
        );
        ok = await template.addIdentity(
          rxAddress,
          `did:ethr:${rxAddress}`,
          web3.utils.sha3('Panama Protege 2020 #3'),
          { from: rxAddress }
        );
      });1

      it('should execute DR from NONE to PRESCRIPTION_SENT', async () => {
        const addr = templAddress;
        const payload = wf.createRlpDocumentPayload({
          wfDocumentModelFn: () => recetaFn({
            description: 'Acetaminofen 100 mg por 7 dias cada 8 horas',
            patient: ['John Lopez', '', '', userAddr],
            doctor: ['Donovan Rodriguez', '', '', doctorAddress],
            pharmacy: ['n','','',userAddr],
            amount: 0,
            tax: 0
          }),
          files: [
            1,
            [
              ['user_content', 'receta.pdf', '/ipfs/receta.pdf']
            ]
          ]
        });

        let tx = await wf.executeStep(template, {
          to: doctorAddress,
          step: wf.getState('NONE'),
          actor: wf.getActor('DR'),
          from: userAddr,
          payload,
        });

        console.log(tx.logs[0], tx.logs[1]);
      });
      it('should execute PATIENT from PRESCRIPTION_SENT to RX_REQUEST', async () => {
        const addr = templAddress;
        const payload = wf.createRlpDocumentPayload({
          wfDocumentModelFn: () => recetaFn({
            description: 'Acetaminofen 100 mg por 7 dias cada 8 horas',
            patient: ['John Lopez', '', '', '0x'],
            doctor: ['Donovan Rodriguez', '', '', '0x'],
            pharmacy: ['Farmacias El Javillo','','','0x'],
            amount: 0,
            tax: 0
          }),
          files: [
            0,
            [
              ['user_content', 'receta.pdf', '/ipfs/receta.pdf']
            ]
          ]
        });

        let tx = await wf.executeStep(template, {
          to: rxAddress,
          step: wf.getState('PRESCRIPTION_SENT'),
          actor: wf.getActor('PATIENT'),
          from: userAddr,
          payload,
        });

        console.log(tx.logs[0], tx.logs[1]);
      });
 
      it('should execute workflow for RX from RX_REQUEST to RX_ACCEPT', async () => {
        const addr = templAddress;
        const payload = wf.createRlpDocumentPayload({
          wfDocumentModelFn: () => recetaFn({
            description: 'Acetaminofen 100 mg por 7 dias cada 8 horas',
            patient: ['John Lopez', '', '', '0x'],
            doctor: ['Donovan Rodriguez', '', '', '0x'],
            pharmacy: ['Farmacias El Javillo','','','0x'],
            amount: 123.10,
            tax: 0.12
          }),
          files: [
            0,
            [
              ['user_content', 'receta.pdf', '/ipfs/receta.pdf'],
            ]
          ]
        });

        let tx = await wf.executeStep(template, {
          to: userAddr,
          step: wf.getState('RX_REQUEST'),
          actor: wf.getActor('RX'),
          from: rxAddress,
          payload,
        });

        console.log(tx.logs[0], tx.logs[1]);
      });
      it('should execute workflow PATIENT from RX_ACCEPT to PATIENT_PAYMENT_SENT', async () => {
        const payload = wf.createRlpDocumentPayload({
          wfDocumentModelFn: () => recetaFn({
            description: 'Acetaminofen 100 mg por 7 dias cada 8 horas',
            patient: ['John Lopez', '', '', '0x'],
            doctor: ['Donovan Rodriguez', '', '', '0x'],
            pharmacy: ['Farmacias El Javillo','','','0x'],
            amount: 123.10,
            tax: 0.12
          }),
          files: [
            0,
            [
              ['user_content', 'receta.pdf', '/ipfs/receta.pdf'],
            ]
          ]
        });

        let tx = await wf.executeStep(template, {
          to: rxAddress,
          step: wf.getState('RX_ACCEPT'),
          actor: wf.getActor('PATIENT'),
          from: userAddr,
          payload,
        });

        console.log(tx.logs[0], tx.logs[1]);
      });
      it('should execute workflow RX from PATIENT_PAYMENT_SENT to PAYMENT_RCV', async () => {
        const addr = templAddress;
        const payload = wf.createRlpDocumentPayload({
          wfDocumentModelFn: () => recetaFn({
            description: 'Acetaminofen 100 mg por 7 dias cada 8 horas',
            patient: ['John Lopez', '', '', '0x'],
            doctor: ['Donovan Rodriguez', '', '', '0x'],
            pharmacy: ['Farmacias El Javillo','','','0x'],
            amount: 123.10,
            tax: 0.12
          }),
          files: [
            1,
            [
              ['user_content', 'receta.pdf', '/ipfs/receta.pdf'],
              ['certfication_content', 'factura.pdf', '/ipfs/factura.pdf']
            ]
          ]
        });

        let tx = await wf.executeStep(template, {
          to: userAddr,
          step: wf.getState('PATIENT_PAYMENT_SENT'),
          actor: wf.getActor('RX'),
          from: rxAddress,
          payload,
        });

        console.log(tx.logs[0], tx.logs[1]);
      });
    });
  });
});
